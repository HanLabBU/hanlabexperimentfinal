function filenameStructure = getNestedFiles(varargin)
if nargin>0
	topDir = varargin{1};
else
	topDir = pwd;
end
dirInfo = dir(topDir);
[~,topDirName] = fileparts(topDir);
topDirName = topDirName(isletter(topDirName) | isnumeric(topDirName));

% Extract Filenames
topFiles = dirInfo(~[dirInfo.isdir]);
filenameStructure.allFiles = {topFiles.name};
filenameStructure.(sprintf('Top_%s',topDirName)) = {topFiles.name};

% Extract Sub-Directories Recursively
subDir = dirInfo([dirInfo.isdir]);
subDir = subDir( ~( ...
	strcmp({subDir.name},'.') ...
	| strcmp({subDir.name},'..')));
if ~isempty(subDir)
	for n  =1:numel(subDir)
		[~,subDirName] = fileparts(subDir(n).name);
		subDirName = subDirName(isletter(subDirName) | isnumeric(subDirName));
		fieldname = sprintf('%s_%s',topDirName,subDirName);
		filenameStructure.(fieldname) = ...
			getNestedFiles(subDir(n).name);
		filenameStructure.allFiles = cat(2,...
			filenameStructure.allFiles,...
			filenameStructure.(fieldname).allFiles);
	end
end
