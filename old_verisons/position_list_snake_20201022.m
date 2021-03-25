clear all
close all
clc
% path = ('G:\Data\AstraZenecca_ICiC\20180629_AZ09_fixed-spheroids_384well_AutomaticPrefinding\');
% file_name = 'positions_384.pos';
% file_data = fileread([path 'file_name']);

pos_path = 'E:\IBIN_Nina\20201029_fixedPlate\positions_pre_2.pos';
% copyfile(pos_path, [pos_path '.backup']);

% replace_hyphens_micromanager(pos_path, 'pos');
file_data = fileread(pos_path);


scale_factor = 5.5; % microns per pixel

row_list    = {'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'};
column_list = {'5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15'};
% row_list = {'C'};
% column_list = {'22'};

row_num = numel(row_list);
column_num = numel(column_list);

% find the start of text for each entry
start_of_elements = strfind(file_data, '"GRID_COL"');

% read in position information from spheroid finding algorithm
% load('E:\AZ\20190517_AZ21_doseResponse_spin_noCO2_roomTemp\FL_top_1\FL_median-filter_stack over-Z\output_data.mat')
load('E:\IBIN_Nina\20201029_fixedPlate\colorPrefind_20201029_5\output_data_best.mat')
output_data = output_data_best;

% load('output_data');
image_fileinfo = [output_data.fileinfo];
image_filenames = {image_fileinfo.name};

new_file_data=file_data([1:min(start_of_elements)-1]);

for row_num = 1:numel(row_list)
    if mod(row_num,2)
        col_num=[15:-1:5]-4;
    else
        col_num=[5:15]-4; 
    end
    for column_num = col_num
        row_num
        column_num
        row_list{row_num}
        column_list{column_num}
        
        
        search_string_entry = ['"LABEL": "Row ' row_list{row_num} ' Column ' column_list{column_num} ' Field 0"']

        start_of_label = strfind(file_data, search_string_entry);
       
        % now find the start_of_element relating to the entry just found
        
        earlier_elements = find(start_of_elements < start_of_label);
        start_of_entry = start_of_elements(earlier_elements(end));
        if earlier_elements(end) >= numel(start_of_elements)
            end_of_entry = numel(file_data);
        else
            end_of_entry = start_of_elements(earlier_elements(end)+1)-1;
        end
        entry_data = file_data(start_of_entry:end_of_entry)
        
        % replace with with JSON parsing, maybe splitting or regexp
        
        search_string_x = '"X": ';
        start_of_x = strfind(entry_data, search_string_x)+length(search_string_x);
        x_length = strfind(entry_data(start_of_x:end), ',');
        end_of_x = start_of_x + x_length(1)-2;
        x_pos = str2num(entry_data(start_of_x:end_of_x))
        
        search_string_y = '"Y": ';
        start_of_y = strfind(entry_data, search_string_y)+length(search_string_y);
        y_length = strfind(entry_data(start_of_y:end), ',');
        end_of_y = start_of_y + y_length(1)-2;
        y_pos = str2num(entry_data(start_of_y:end_of_y))
        
        file_index = [];
        for k = 1:numel(image_filenames)
            % now use regexp - instead of this used the saved row and col?
            row = regexp(image_filenames{k}, '(?<=Row[-\s])[A-Z]+', 'match');
            col = regexp(image_filenames{k}, '(?<=Column[-\s])[0-9]+', 'match');
            %if strcmp(column_list{column_num}, '13')
            fprintf('column %s', col{1});
            co = column_list{column_num}
            fprintf('row %s', row{1});
            ro = row_list{row_num}
            % search_string_file_name
            if strcmp(col{1}, column_list{column_num}) && strcmp(row{1}, row_list{row_num})
                'here'
                file_index = k
            end
            %end
            fprintf('-----------------\n')
        end
        
        if file_index == []
            Error('Well %s%s does not exist in data', row_list{row_num}, ...
                column_list{column_num});
        end
        
        output_data(file_index).xpos
        output_data(file_index).ypos
        x_shift = ((output_data(file_index).xpos - 1004/2)*scale_factor)+50   % Add to shift spheroids in center of FOV of 60X objective
        y_shift = ((output_data(file_index).ypos - 1002/2)*scale_factor)+250  % Add to shift spheroids in center of FOV of 60X objective
                    
        new_x = num2str(x_pos-x_shift)
        new_y = num2str(y_pos-y_shift)
        
        if ~isnan(output_data(file_index).xpos)
            %Create a new string with modified x position
            new_string=strrep(file_data([start_of_entry:end_of_entry]),num2str(x_pos),num2str(new_x));
            
            %Modify the y position in the new string
            new_string=strrep(new_string,num2str(y_pos),num2str(new_y));
            new_file_data =[new_file_data new_string];
           
    % Add all of this to new_file_data
    % new_file_data=[new_file_data strrep(file_data([start_of_entry:end_of_entry]),num2str(y_pos),num2str(new_y))];
        end
      
              
    end
end

% new_file_data([end-18:end])=[];
% new_file_data=[new_file_data file_data([end-6:end])];

dlmwrite(['E:\IBIN_Nina\20201029_fixedPlate\positions_final.pos'], new_file_data,'delimiter','');

