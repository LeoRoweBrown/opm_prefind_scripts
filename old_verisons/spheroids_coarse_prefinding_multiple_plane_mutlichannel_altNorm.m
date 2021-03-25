clc;	    % Clear command window.
clf;
clear;	    % Delete all variables.
close all;	% Close all figure windows except those created by imtool.
workspace;	% Make sure the workspace panel is showing
set(0,'defaultAxesFontSize',20)
exposureTime = 50;

%suffix for file saving
suff = '20201022';
% 
% r1 = 30;    % radius of ball element
% r2 = 34;    % radius of outer disk element

r1 = 26;    % radius of ball element
r2 = 30;    % radius of outer disk element

% plot_and_save_figs = false;

% det_threshold = 6; % detection threshold (above which all included) for presence of spheroid
% NORMALISE
det_threshold = 7; % detection threshold (above which all included) for presence of spheroid

rd = r2-r1;

[x_mesh, y_mesh] = meshgrid(-r2:r2, -r2:r2);
r_mesh = sqrt(x_mesh.^2+y_mesh.^2);

ball_element = sqrt(r1^2-r_mesh.^2);
ball_element(r_mesh > r1) = 0;
ball_element = ball_element/sum(ball_element(:));

ring_element = ones(size(r_mesh));
ring_element(r_mesh < r1 | r_mesh >= r2) = 0;
ring_element = ring_element/sum(ring_element(:));

total_element = ball_element - ring_element;

% figure (1); imagesc(ball_element); colorbar
% figure (2); imagesc(ring_element); colorbar
% figure (3); imagesc(total_element); colorbar
row_list = 5:12;
col_list = 5:15;
%%
path_root = 'E:\IBIN_Nina\20201008_fixedPlatePrefindTest';

path_list = {
    [path_root '\LED_430_2'];
    [path_root '\LED_505_2'];
    [path_root '\LED_565_2'];
    [path_root '\LED_625_2'];
    };

color_path = [path_root '\color' suff];

if exist(color_path, 'dir')
    fprintf('Deleting data in %s\n', color_path);
    failed_files = [color_path '\' 'failed\*'];
    found_files = [color_path '\' 'found\*'];
    delete(failed_files)
    delete(found_files)
end

mkdir(color_path);


% Dye-LED mappings in this table:
% seems a bit of a stupid method
led_table = readtable([path_root '\dichroics.xls']);
leds = led_table{:, 'LED'};
dyes = led_table{:, 'dye'};
filters = led_table{:, 'dichroic'};

%% sort path_list so it's correct compared to leds
% sort the paths
pathjoin = strjoin(path_list,',');
path_leds = regexp(pathjoin, '(?<=LED_)[0-9]+', 'match');
[sorted, index] = sort(path_leds);
path_list = path_list(index);
% now sort leds as well
[leds, leds_index] = sort(leds);
dyes = dyes(leds_index);
filters = filters(leds_index);

for i_dye = 1:numel(dyes)
    dye_platemap{i_dye} = xlsread([path_root '\platemap_dyes.xls'], dyes{i_dye});
end

% list of path locations for each focus and each LED wavelength/filter
for i_led = 1:numel(path_list)
    led_path = path_list{i_led};
    path_bottom{i_led} = [led_path '\FL_bottom_50ms_1'];
    path_focus{i_led} = [led_path '\FL_focus_50ms_1'];
    path_top{i_led} = [led_path '\FL_top_50ms_1'];
    
    % Read images from Images folder
    imgs_bottom{i_led} = dir(fullfile( path_bottom{i_led},'*.tif'));
    imgs_focus{i_led} = dir(fullfile(path_focus{i_led},'*.tif'));
    imgs_top{i_led} = dir(fullfile(path_top{i_led},'*.tif'));
    
    max_val_array{i_led} = zeros(1, length(imgs_bottom));
end

% path1 = 'E:\AZ\20190517_AZ21_doseResponse_spin_noCO2_roomTemp'

% Read images from Images folder
% imgs_bottom = dir(fullfile(path_bottom,'*.tif'));
% imgs_focus = dir(fullfile(path_focus,'*.tif'));
% imgs_top = dir(fullfile(path_top,'*.tif'));
count_checker = 0;
test_area = zeros(16,24);

    
% get normalisation factors
% getPrefindNorm(imgs_bottom{1})

col_array = cell(length(imgs_bottom{1}), 2);
row_array = cell(length(imgs_bottom{1}), 2);
img_in_array = cell(numel(path_list));
img_channel_mean = zeros(numel(path_list), 1);
n = ones(numel(path_list), 1); % keep track of number of images for each channel
include_in_analysis = logical(zeros(length(imgs_bottom{1}), numel(path_list)));

for j=1:length(imgs_bottom{1})
    % parse well label
    nameToParse = imgs_bottom{1}(j).name;
    row = regexp(nameToParse, '(?<=Row\s)[A-Z]+', 'match');
    col = regexp(nameToParse, '(?<=Column\s)[0-9]+', 'match');
    if isempty(row)
       row = regexp(nameToParse, '(?<=Row-)[A-Z]+', 'match');
    end
    if isempty(col)
        col = regexp(nameToParse, '(?<=Column-)[0-9]+', 'match');
    end
    row = row{1}; col = col{1}; % col = strjoin(col, ''); % 2 digits returned separately
    rowNum = double(row - 'A' + 1);
    colNum = str2double(col);
    if colNum < 5 || colNum > 15
        nameToParse
        col
        error("Col out of bounds!")
    end
    col_array{j}{:} = {row, rowNum};
    row_array{j}{:} = {col, colNum};

    for i = 1:numel(path_list) % loop over each LED channel
        % get info about the LED used on this data and see whether it
        % should be ignored or not

        % search if LED channels are appropriate (if there is a dye close
        % to the wavelength 
        test_area(rowNum, colNum) = 1;
        % if the current channel does not match dyes in well
        if dye_platemap{i}(rowNum, colNum) == 0
            continue
        else
            fprintf(['Including into analysis: dye - %s, row - %s, ', ...
                'col - %s, LED - %d\n'], dyes{i}, row, col, leds(i));
            include_in_analysis(j, i) = true;
            count_checker = count_checker + 1;
        end

        img_in_bottom = imread(fullfile(path_bottom{i},imgs_bottom{i}(j).name));  % Read image
        img_in_focus = imread(fullfile(path_focus{i},imgs_focus{i}(j).name));  % Read image
        img_in_top = imread(fullfile(path_top{i},imgs_top{i}(j).name));  % Read image

        stack_of_three_images(1, :, :) = img_in_bottom;
        stack_of_three_images(2, :, :) = img_in_focus;
        stack_of_three_images(3, :, :) = img_in_top;

        img_in = squeeze(median(stack_of_three_images, 1));
        img_in_array{i}{j} = img_in;
        img_channel_mean(i) = img_channel_mean(i) + ... 
            (mean(img_in(:)) - img_channel_mean(i))/n(i);
        n(i) = n(i) + 1; % number of means for ith channel
        %{
        figure
        imagesc(img_in)
        pause
        %}
    end
end
mean_of_means = mean(img_channel_mean);
%% 2nd loop for normalising and conv
for j=1:length(imgs_bottom{1})
    output_data_best(j).filter_list = [];
    max_val_array{j} = zeros(numel(path_list), 1);
    for i = 1:numel(path_list) % loop over each LED channel
        if ~include_in_analysis(j, i)
            continue;
        end
        % make so mean is the same across channels
        img_in_norm = (double(img_in_array{i}{j})/img_channel_mean(i))*mean_of_means;
        
        img_in_conv = conv2(img_in_norm, total_element, 'valid');

        img_in_conv = padarray(img_in_conv, [r2, r2], 0, 'both');

        [max_val, max_element] = max(img_in_conv(:));

        if max_val >= det_threshold
            [max_y, max_x] = ind2sub(size(img_in_conv), max_element);
            spheroid_detected = true;
        else
            max_y = NaN; max_x = NaN;
            spheroid_detected = false;
        end

        spheroid_detected

        %% figure (5)

        % if plot_and_save_figs
        f_conv = figure(1);
            imagesc(img_in_conv); colorbar
            hold on
            plot(max_x, max_y, 'X', 'color', 'red')
            hold off
        % end

        X(j)= max_x; % transpose(X)
        Y(j)= max_y; % transpose(Y)

        % if plot_and_save_figs
            save_path = [path_list{i} '\' suff];
            % path1 = ('E:\AZ\20190517_AZ21_doseResponse_spin_noCO2_roomTemp\FL_top_1\FL_median-filter_stack over-Z');
            mkdir([save_path '\spheroid in false-color-data'])
            saveas(f_conv, fullfile([save_path '\spheroid in false-color-data'],['false-colour-data' imgs_bottom{i}(j).name]))

            f_raw = figure(2);
            imagesc(img_in_norm); colormap gray
            hold on
            plot(X(j), Y(j), 'X', 'color', 'red')
            title(sprintf('Max from conv: %.1f', max_val));
            hold off

            mkdir([save_path '\spheroid in raw-data'])
            saveas(f_raw, fullfile([save_path '\spheroid in raw-data'],['raw-data' imgs_bottom{i}(j).name]))
        % end

        %%
        % swapped idx so can compute maximum of max_val for each chnl
        
        output_data{i}(j).fileinfo = imgs_bottom{i}(j);
        output_data{i}(j).xpos = max_x;
        output_data{i}(j).ypos = max_y;
        output_data{i}(j).filter = filters{i};
        output_data{i}(j).row = row;
        output_data{i}(j).col = col;
        output_data{i}(j).spheroid_detected = spheroid_detected;
        output_data{i}(j).max_val = max_val;
        
        if max_val > max(max_val_array{j}(:))
            output_data_best(j).fileinfo = imgs_bottom{i}(j);
            output_data_best(j).xpos = max_x;
            output_data_best(j).ypos = max_y;
            output_data_best(j).filter = filters{i};
            output_data_best(j).row = row;
            output_data_best(j).col = col;
            output_data_best(j).max_val = max_val;
            
            mkdir([color_path '\all']);
            saveas(f_raw, fullfile([color_path '\all'],imgs_bottom{i}(j).name));
            if max_val > det_threshold
                mkdir([color_path '\found']);
                saveas(f_raw, fullfile([color_path '\found'],imgs_bottom{i}(j).name));
            else
                % saves the best failed 
                mkdir([color_path '\failed']);
                saveas(f_raw, fullfile([color_path '\failed'],imgs_bottom{i}(j).name));
            end
        end
        
        max_val_array{j}(i) = max_val;
        output_data_best(j).filter_list(i) = string(filters{i});
        
    end
    if max(max_val_array{j}(:)) < det_threshold
        fprintf('No spheroid found for row: %s col: %s', row, col);
        output_data_best(j).spheroid_detected = false;
    else
        output_data_best(j).spheroid_detected = true;
    end
end

%% Commented out histogram for now
% figure(3)
% hist(max_val_array, 400)

% save the co-ordinates of spheroids
% imgs_bottom.name
% save('X', 'X')
% save('Y', 'Y')
count_checker
save([color_path '\output_data'] , 'output_data', 'output_data')
save([color_path '\output_data_best'] , 'output_data_best')
