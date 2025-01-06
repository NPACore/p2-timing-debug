function [startTimestamp,endTimestamp,startFlip,endFlip] = getTimestampsFromMatDiary(matlabDiaryPath,txtDiaryPath)
    % Gets the start, end timestamps and flip times given the .mat and diary files
    % 
    % Parameters:
    % matlabDiaryPath - [string] Path to the matlab diary
    % txtDiaryPath - [string] Path to the diary file (without extension)
    % 
    % Returns:
    % startTimestamp - [datetime] Start timestamp
    % endTimestamp - [datetime] End timestamp
    % startFlip - [double] Start flip from the diary file
    % endFlip - [double] End flip 

    % Load the data
    matDiaryStruct = load(matlabDiaryPath);
    
    % Extract the clock start time 
    clock_start = matDiaryStruct.clock_start;
    startTimestamp = datetime(clock_start(1), clock_start(2),clock_start(3), clock_start(4), clock_start(5), clock_start(6),'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    
    % Extract the order variable
    orderArray = matDiaryStruct.order;

    % Get the last index with values
    nonEmptyCells = ~cellfun('isempty', orderArray);
    lastTrialInd = find(nonEmptyCells,1,'last');
    
    % Calculate Run duration
    lastRunRow = orderArray{lastTrialInd};
    runDuration = lastRunRow{13}+lastRunRow{14};
    
    % Calculate the end timestamp
    endTimestamp = startTimestamp+ seconds(runDuration);
    
    % Get the pulse flip value
    startFlip = getPulseFlipValue(txtDiaryPath);
    endFlip = startFlip + runDuration;

end


function value = getPulseFlipValue(filePath)

    % Open the file for reading
    fileID = fopen(filePath, 'r');

    if fileID == -1
        error('File could not be opened. Check the file path and permissions.');
    end

    % Initialize the value 
    value = NaN;

    % Read the file line by line
    while ~feof(fileID)
        line = fgetl(fileID);
        % Search for the line containing "pulse flip"
        index = strfind(line, 'pulse flip:');
        if ~isempty(index)
            % Extract the part of the line after "pulse flip"
            remainingLine = strtrim(line(index(1) + length('pulse flip:'):end));
            % Convert the string to a number
            value = sscanf(remainingLine, '%f', 1);
            break;
        end
    end

    % Close the file
    fclose(fileID);

    % Check if the value was found
    if isnan(value)
        warning('The pulse flip was not found in the file.');
    end

    % Return the found value
    return;
end
