clear all
close all
clc
% path = ('G:\Data\AstraZenecca_ICiC\20180629_AZ09_fixed-spheroids_384well_AutomaticPrefinding\');
% file_name = 'positions_384.pos';
% file_data = fileread([path 'file_name']);

file_data = fileread('E:\AZ\20190517_AZ21_doseResponse_spin_noCO2_roomTemp\positions_xls.pos');

scale_factor = 5.5; % microns per pixel

row_list    = {'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N'};
column_list = {'3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22'};
% row_list = {'C'};
% column_list = {'22'};

row_num = numel(row_list);
column_num = numel(column_list);

% find the start of text for each entry
start_of_elements = strfind(file_data, '"GRID_COL"');

% read in position information from spheroid finding algorithm
load('E:\AZ\20190517_AZ21_doseResponse_spin_noCO2_roomTemp\FL_top_1\FL_median-filter_stack over-Z\output_data.mat')
% load('output_data');
image_fileinfo = [output_data.fileinfo];
image_filenames = {image_fileinfo.name};

new_file_data=file_data([1:min(start_of_elements)-1]);

for row_num = 1:row_num
    if mod(row_num,2)
        col_num=[22:-1:3]-2;
    else
        col_num=[3:22]-2; 
    end
    for column_num = col_num
        
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
        
        search_string_file_name = ['Row ' row_list{row_num} ' Column ' column_list{column_num}];
        
        file_index = [];
        for k = 1:numel(image_filenames)
            string_comparison_result = strfind(image_filenames{k}, search_string_file_name);
            if ~isempty(string_comparison_result)
                file_index = k
            end
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

dlmwrite(['E:\AZ\20190517_AZ21_doseResponse_spin_noCO2_roomTemp\positions_prefinal.pos'], new_file_data,'delimiter','');

