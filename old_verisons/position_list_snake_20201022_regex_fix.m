clear all
close all
clc

addpath('prettyjson');

% path = ('G:\Data\AstraZenecca_ICiC\20180629_AZ09_fixed-spheroids_384well_AutomaticPrefinding\');
% file_name = 'positions_384.pos';
% file_data = fileread([path 'file_name']);

% pos_path = 'E:\IBIN_Nina\20201029_fixedPlate\positions_pre.pos';
% pos_path = 'G:\Data\IBIN_Nina\20201029_fixedPlate\positions_pre.pos';
pos_path = 'U:\IBIN_Nina\20201120_leoTraining\positions_prefind.pos'

% copyfile(pos_path, [pos_path '.backup']);

% replace_hyphens_micromanager(pos_path, 'pos');
file_data = fileread(pos_path);


scale_factor = 5.5; % microns per pixel

% row_list    = {'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'};
% column_list = {'5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15'};
row_list = {'H'};
column_list = {'5', '6', '7', '8', '9', '10'};

column_num = numel(column_list);

% read in position information from spheroid finding algorithm
% load('E:\AZ\20190517_AZ21_doseResponse_spin_noCO2_roomTemp\FL_top_1\FL_median-filter_stack over-Z\output_data.mat')
% load('E:\IBIN_Nina\20201029_fixedPlate\colorPrefind_20201029_5\output_data_best.mat')
% load('G:\Data\IBIN_Nina\20201029_fixedPlate\colorPrefind_20201029_5\output_data_best.mat')
load('U:\IBIN_Nina\20201120_leoTraining\colorPrefind_20201029_5\output_data_best.mat')

output_data = output_data_best;

% load('output_data');
image_fileinfo = [output_data.fileinfo];
image_filenames = {image_fileinfo.name};

json_data = jsondecode(file_data);

pos_labels = {json_data.POSITIONS.LABEL};
% combine all labels into a character array (contains row and column info)
pos_labels_join = [pos_labels{:}];
% device field contains x and y positions
pos_device_xy = {json_data.POSITIONS.DEVICES};

% get cell array of the rows and cols in the positions list file via regex
row_list_regx = regexp(pos_labels_join, '(?<=Row[-\s])[A-Z]+', 'match');
col_list_regx = regexp(pos_labels_join, '(?<=Column[-\s])[0-9]+', 'match');

for row_num = 1:numel(row_list)
    column_numbers = str2double(column_list);
    % snaking motion:
    if mod(row_num,2)
        col_num = numel(column_list):-1:1;
    else
        col_num = 1:1:numel(column_list);
    end
    for column_num = col_num
        row_num
        column_num
        row_list{row_num}
        column_list{column_num}
        
        % replace with with JSON parsing
        % add some robustness, it probably is in order already but, yeah:
        
        % find row and column specified by loop indices in .pos file
        curent_row_pos = strcmp(row_list_regx, row_list{row_num});
        curent_col_pos = strcmp(col_list_regx, column_list{column_num});
        % index of well in pos list given by current row_list{row_num} and
        % column_list{column_num}
        well_pos_idx = and(curent_row_pos, curent_col_pos);
        
        x_pos = pos_device_xy{well_pos_idx}.X;
        y_pos = pos_device_xy{well_pos_idx}.Y;
        
        % old code read filenames to match wells, new code uses the col
        % and row directly from output_data (included in the .mat in the
        % new pre-find code)
        % now find the index for the current well in output_data.mat
        curent_row_mat = strcmp({output_data.row}, row_list{row_num});
        curent_col_mat = strcmp({output_data.col}, column_list{column_num});
        % index of current well in output_data
        well_mat_idx = and(curent_row_mat, curent_col_mat);
        
        if ~any(well_mat_idx)
            error('Well %s%s does not exist in data', row_list{row_num}, ...
                column_list{column_num});
        end
        
        output_data(well_mat_idx).xpos
        output_data(well_mat_idx).ypos
        x_shift = ((output_data(well_mat_idx).xpos - 1004/2)*scale_factor)+50   % Add to shift spheroids in center of FOV of 60X objective
        y_shift = ((output_data(well_mat_idx).ypos - 1002/2)*scale_factor)+250  % Add to shift spheroids in center of FOV of 60X objective
                    
        new_x = num2str(x_pos-x_shift)
        new_y = num2str(y_pos-y_shift)
        
        % This SHOULD work but micromanager doesn't like my JSONs
        if ~isnan(output_data(well_mat_idx).xpos)
            % Replace x and y positions in temp structure
            pos_device_xy{well_pos_idx}.X = num2str(new_x);
            pos_device_xy{well_pos_idx}.Y = num2str(new_y);
            % replace DEVICES field for each entry in POSITIONS
            [json_data.POSITIONS.DEVICES] = pos_device_xy{:};
        end
        
%         if ~isnan(output_data(well_mat_idx).xpos)
%             %Create a new string with modified x position
%             new_string=strrep(file_data([start_of_entry:end_of_entry]),num2str(x_pos),num2str(new_x));
%             
%             %Modify the y position in the new string
%             new_string=strrep(new_string,num2str(y_pos),num2str(new_y));
%             new_file_data =[new_file_data new_string];
%            
%         end
        
    end
end

% Again, my JSON method doesn't work with micromanager - investigate this
% re-encode json (readable format)
new_file_data = jsonencode(json_data);
% add linebreaks after commas, brackets
% https://github.com/ybnd/prettyjson.m
new_file_data = prettyjson(new_file_data);


% dlmwrite(['E:\IBIN_Nina\20201029_fixedPlate\positions_final_reg.pos'], new_file_data,'delimiter','');
% dlmwrite(['G:\Data\IBIN_Nina\20201029_fixedPlate\positions_final_reg.pos'], new_file_data,'delimiter','');
dlmwrite(['U:\IBIN_Nina\20201120_leoTraining\positions_final_json.pos'], new_file_data,'delimiter','');
