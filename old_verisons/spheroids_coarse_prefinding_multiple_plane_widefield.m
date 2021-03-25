clc;	    % Clear command window.
clf;
clear;	    % Delete all variables.
close all;	% Close all figure windows except those created by imtool.
workspace;	% Make sure the workspace panel is showing
set(0,'defaultAxesFontSize',20)

projection = 'median';

r1 = 30;    % radius of ball element
r2 = 34;    % radius of outer disk element

% plot_and_save_figs = false;

det_threshold = 5; % detection threshold (above which all included) for presence of spheroid

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

%%
path_root = 'Z:\Projects\OPM\Nina_project\prefind\20201008_fixedPlatePrefindTest\widefield\';
path_bottom = [path_root '\FL_bottom_50ms_1'];
path_focus = [path_root '\FL_focus_50ms_1'];
path_top = [path_root '\FL_top_50ms_1'];

save_path = [path_root '\' projection];

% path1 = 'E:\AZ\20190517_AZ21_doseResponse_spin_noCO2_roomTemp'

% Read images from Images folder
imgs_bottom = dir(fullfile(path_bottom,'*.tif'));
imgs_focus = dir(fullfile(path_focus,'*.tif'));
imgs_top = dir(fullfile(path_top,'*.tif'));

max_val_array = zeros(1, length(imgs_bottom));

for j=1:length(imgs_bottom)

    j

    img_in_bottom = imread(fullfile(path_bottom,imgs_bottom(j).name));  % Read image
    img_in_focus = imread(fullfile(path_focus,imgs_focus(j).name));  % Read image
    img_in_top = imread(fullfile(path_top,imgs_top(j).name));  % Read image

    % img_in_bottom = imcomplement(img_in_bottom);
    % img_in_focus = imcomplement(img_in_focus);
    % img_in_top = imcomplement(img_in_top);


    stack_of_three_images(1, :, :) = img_in_bottom;
    stack_of_three_images(2, :, :) = img_in_focus;
    stack_of_three_images(3, :, :) = img_in_top;

    if strcmp(projection, 'median')
        img_in = squeeze(median(stack_of_three_images, 1));
    elseif strcmp(projection, 'mean')
        img_in = squeeze(mean(stack_of_three_images, 1));
    elseif strcmp(projection, 'max')
        img_in = squeeze(max(stack_of_three_images, 1));
    end
    
    imbw = imbinarize(img_in);
    imbw = imclose(imbw, ones(3));
    bwcon = bwconncomp(imbw);
    for comp = 1:numel(bwcon);
        
    %{
    figure
    imagesc(img_in)
    pause
    %}

    img_in_conv = conv2(img_in, total_element, 'valid');

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

    max_val_array(j) = max_val;


    %% figure (5)

    % if plot_and_save_figs
        imagesc(img_in_conv); colorbar
        hold on
        plot(max_x, max_y, 'X', 'color', 'red')
        hold off
    % end

    X(j)= max_x; % transpose(X)
    Y(j)= max_y; % transpose(Y)

    % if plot_and_save_figs

        % path1 = ('E:\AZ\20190517_AZ21_doseResponse_spin_noCO2_roomTemp\FL_top_1\FL_median-filter_stack over-Z');
        mkdir([save_path '\spheroid in false-color-data'])
        saveas(gcf, fullfile([save_path '\spheroid in false-color-data'],['false-colour-data' imgs_bottom(j).name]))


        imagesc(img_in); colormap gray
        hold on
        plot(X(j), Y(j), 'X', 'color', 'red')
        hold off

        mkdir([save_path '\spheroid in raw-data'])
        saveas(gcf, fullfile([save_path '\spheroid in raw-data'],['raw-data' imgs_bottom(j).name]))
    % end

    %%

    output_data(j).fileinfo = imgs_bottom(j);
    output_data(j).xpos = max_x;
    output_data(j).ypos = max_y;

end

figure
hist(max_val_array, 400)

% save the co-ordinates of spheroids
% imgs_bottom.name
% save('X', 'X')
% save('Y', 'Y')

save([save_path '\output_data'] , 'output_data', 'output_data')
