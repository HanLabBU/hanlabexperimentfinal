function data = readBinaryData(fileNameInput)
% ------------------------------------------------------------------------------
% READBINARYDATA
% 7/30/2015
% Mark Bucklin
% ------------------------------------------------------------------------------
%
% DESCRIPTION:
%
%
%
% USAGE:
% >>  data = readBinaryData();
% >>  data = readBinaryData(fileName);
%
%
% See also:
%			PROCESSFAST, WRITETIF, WRITEBINARYDATA
% ------------------------------------------------------------------------------
% ------------------------------------------------------------------------------
% ------------------------------------------------------------------------------

% FIND FILE TO READ
if nargin < 1
    fileNameInput = '';
end

% CALL RECURSIVELY FOR CELL INPUT
if iscell(fileNameInput)
    for k = 1:numel(fileNameInput)
        dataCell{k} = readBinaryData(fileNameInput{k});
    end
    data = cat(ndims(dataCell{1}), dataCell{:});
    
else
    % READ INDIVIDUAL FILE
    if ~exist(fileNameInput,'file')
        [fname_fext, fdir] = uigetfile('*.*','MultiSelect', 'on');
        if iscell(fname_fext)
            for k=1:numel(fname_fext)
                dataCell{k} = readBinaryData([fdir,fname_fext{k}]);
            end
            data = cat(ndims(dataCell{1}), dataCell{:});
            return
        end
        fileName = fullfile(fdir,fname_fext);
    else
        fileName = which(fileNameInput);
        if isempty(fileName)
            fileName = fileNameInput;
        end
        [~, fname,fext] = fileparts(fileNameInput);
        if isempty(fext)
            fname_fext = fname;
        else
            fname_fext = [fname,fext];
        end
    end
    
    % DETERMINE SIZE & TYPE OF DATA
    [fname, rem] = strtok(fname_fext,'.');
    arraySizeString = strtok(regexp(rem, '(\d+)\.','match'),'.');
    dataNumDimensions = numel(arraySizeString);
    charIdx = regexp(rem, '(\d+)\.','end');
    for k=dataNumDimensions:-1:1
        dimString = arraySizeString{k};
        dataSize(k) = str2double(dimString);
    end
    dataType = rem(1+charIdx(end):end);
    
    % READ
    fid = fopen(fileName, 'r');
    data = fread(fid, inf, ['*',dataType]);
    fclose(fid);
    
    % RESHAPE
    try
        data = reshape(data, dataSize);
    catch
        try
            dataSizeCell = num2cell(dataSize);
            data = reshape(data, dataSizeCell{1:end-1}, []);
        catch
            
        end
    end
    
end
end



