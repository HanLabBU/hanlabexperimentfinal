
% Find 'FileList' Mat Files
filesfound = false;
useddatafilenames = cell.empty(0,1);
exptDir = pwd;
while ~filesfound
		exptDirList = what(exptDir);
		matFileList = exptDirList.mat;
		fileListFiles = strncmp('FileList',matFileList,8);
		fileListFiles = matFileList(fileListFiles);
		if isempty(fileListFiles)
				fprintf('No FileList files found in: %s\n',exptDir);
				exptDir = uigetdir(pwd,'Locate Experiment Directory');
		else
				filesfound = true;
		end
end
% Concatenate All DataSet Files in Each FileList
for sysnum = 1:numel(fileListFiles)
		fileList = struct2cell(load(fullfile(exptDir,fileListFiles{sysnum})));
		fileList = fileList{1}';
		datafilename = [];
		datafiles = cell(size(fileList));
		for setnum = 1:numel(fileList)
				try
						datafilestruct = load(fullfile(exptDir,fileList{setnum}));
				catch
						datafilestruct = load(fileList{setnum});
				end
				if isempty(datafilename)
						datafilename = fields(datafilestruct);
						datafilename = datafilename{1};
				end
				datafiles{setnum} = datafilestruct.(datafilename);
		end
		% Change Variable Name if Used by Multiple Systems (e.g. vidfiles or behfiles)
		namemod = 2;
		while any(strcmp(datafilename,useddatafilenames))
				datafilename = [datafilename,num2str(namemod)];
				namemod = namemod+1;
		end
		useddatafilenames{sysnum} = datafilename;
		datafileoutput.(datafilename) =  cat(2,datafiles{:});
		% Create Filename from FileList Filename and Save
		[~,fname] = strtok(fileListFiles{sysnum},'_');
		fname = ['DataSet',fname];
		fname = fullfile(exptDir,fname);
		fprintf('Saving concatenated DataSet \n\tFilename: %s\n\tVariable Name: %s\n',...
				fname,datafilename);
		save(fname,'-struct','datafileoutput','-v6');
end



