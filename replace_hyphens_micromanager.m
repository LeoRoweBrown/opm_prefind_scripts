function [code] = replace_hyphens_micromanager(input,type)
% Replace hyphens in either tifs or position list created
% by old micromanager
switch type
    case 'images'
        imgs = input;
        for j=1:length(imgs)
            % TODO think about making loop for the Z views
            fn = imgs(j).name;
            fn_dir = imgs(j).folder;
            fn_fin = strrep(fn, '-', ' ');
            if ~strcmp(fn, fn_fin)
                movefile([fn_dir '\' fn], [fn_dir '\' fn_fin]);
            end
        end
        code = 0;
        return
    case 'pos' % position file (path)
        % do json reading stuff here
        % error("not implemeted");
        pos_file = fileread(input);
        pos_json = jsondecode(pos_file);
        pos_labels = {pos_json.POSITIONS.LABEL};
        pos_labels = strrep(pos_labels, '-', ' ');
        [pos_json.POSITIONS.LABEL] = pos_labels{:};

        json_out = jsonencode(pos_json);
        % Write to a json file
        fid = fopen(input, 'w');
        fprintf(fid, '%s', json_out);
        fclose(fid);
        code = 0;
        return
end
code = {"1 - invalid method, use 'images' to change image filenames or"+...
        " 'positions' for fixing pos file."};

end

