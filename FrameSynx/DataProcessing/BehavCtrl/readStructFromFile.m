function [someStruct,cof] = readStructFromFile(someStruct,fid,rewind);
% takes as input a MATLAB struct with the values in each field specifying
% the data type to read

fields = fieldnames(someStruct);

originalPos = ftell(fid);

for n=1:length(fields)
   
    tmp = fread(fid,prod(someStruct(2).(fields{n})),someStruct(1).(fields{n}));
    if length(someStruct(2).(fields{n}))>1
        tmp = reshape(tmp,someStruct(2).(fields{n}));
    end
    
    switch someStruct(1).(fields{n})
        case 'char'
            someStruct(1).(fields{n}) = char(tmp)';
        otherwise
            someStruct(1).(fields{n}) = tmp;
    end
end

someStruct = someStruct(1);

% rewind the file
if rewind
    cof = ftell(fid);
    fseek(fid,originalPos-cof,'cof');
end

% cof = ftell(fid);
% fields = fieldnames(someStruct);
% 
% originalPos = ftell(fid);
% 
% for n=1:length(fields)
%     dataType = ''; dataSize = 1;
%     dataTypeAndSize = someStruct.(fields{n});
%     [dataType,R] = strtok(dataTypeAndSize,'[]');
%     if ~isempty(R) [dataSize,R] = strtok(R,'[]'); dataSize = str2double(dataSize); end
%     
%     [tmp,c] = fread(fid,dataSize,dataType);
%     
%     if strcmp(dataType,'char')
%         tmp = char(tmp)';    
%     end
%     
%     keyboard;
%     
%     someStruct.(fields{n}) = tmp;
% end
% 
% % rewind the file
% if rewind
%     cof = ftell(fid);
%     fseek(fid,originalPos-cof,'cof');
% end
% 
% cof = ftell(fid);