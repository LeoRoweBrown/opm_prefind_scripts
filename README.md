Scripts for the prefind stage for the 712 OPM setup:
Steps:
0 - Generate positions list using the scipt in mmgr-opm-scripts/utils
1 - Acquire 4x epifluorescent images of all wells with the correct directory for
    each LED and foci - focus, above, below focus. (Root dir is LED wavelength,
    subdir of that is focus) i.e. LED_505/FL_top_50ms
2 - In the MATLAB pre-finding script, Set up the directory names, make sure
    there is a table which contains columns: LED wavelength, (target) dye name
    (to work with spreadsheet book names). Prepare spreadsheet that has
    platemap with books for each dye and a 1 where there is a spheroid with
    that dye and 0 for where there is not. Book names must be the same name as
    in the LED table
3 - Running the script in (2) will output two MATLAB .mat files. 
    Use output_best.mat in the positions list generator script - this .mat
    file contains the (likely) best estimate of spheroid position in the FOV
    across all LEDs (some spheroids have multiple dyes). The position list
    script outputs a position list with XY positions for the 60x but no Z pos.
4 - TODO - zprefind script in micro-manager - use the positions list and run
    this to get the Z positions. Use brightfield illumination.
