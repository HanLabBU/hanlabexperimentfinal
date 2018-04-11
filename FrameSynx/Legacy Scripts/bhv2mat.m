%
% BHV2MAT converts .bhv files to .mat files
%
function bhv2mat(inFile,outFile)

if nargin < 2
    [path,file,ext] = fileparts(inFile);
    outFile = [path,file,'.mat'];
end

[header,trials] = readBhvFile(inFile);
save(outFile,'header','trials');