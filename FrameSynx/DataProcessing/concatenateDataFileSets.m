function varargout = concatenateDataFileSets()
dbstop if error
% Find 'FileList' Mat Files
filesfound = false;
useddatafilenames = cell.empty(0,1);
datasetfilenames = cell.empty(0,1);
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
				exptDir = pwd;
		end
		%If 'FileList' Files Aren't Found -> Create Them
		if isempty(fileListFiles)
			a = dir(exptDir);
			fnames = {a.name};
			vidfilecells = strfind(fnames,'Dalsa');
			behfilecells = strfind(fnames,'Behavior');
			numb = 0;
			numv = 0;
			
			aux1 = strfind(fnames, 'SET');
			aux2 = strfind(fnames, '.mat');
			
			
			for n = 1:numel(fnames)
				% Check if is a 'dataset file', identified by particle "SET"
				if isempty(aux1{n})
					continue					
				end
				thisfname = fnames{n};
				% Check it if is a video file
				if ~isempty(vidfilecells{n})
					vidfiles{numv+1} = fnames{n};
				  vidfilesSETnumber(numv+1) = str2num(thisfname(aux1{n}+3:aux2{n}-1));
					numv = numv+1;
				end
				% Check it if is a behavior file
				if ~isempty(behfilecells{n})
					behfiles{numb+1} = fnames{n};
					behfilesSETnumber(numb+1) = str2num(thisfname(aux1{n}+3:aux2{n}-1));
					numb = numb+1;
				end
			end
			
			[~,vindex] = sort(vidfilesSETnumber);
			[~,bindex] = sort(behfilesSETnumber);
			
			vidfiles = vidfiles(vindex);
			behfiles = behfiles(bindex);
			
			fileListFiles{1} = 'FileList_VideoFiles.mat';
			fileListFiles{2} = 'FileList_BehaviorFiles.mat';
			save(fileListFiles{1},'vidfiles');
			save(fileListFiles{2},'behfiles');
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
		datafileoutput = struct(datafilename, cat(2,datafiles{:}));
		% Create Filename from FileList Filename and Save
		[~,fname] = strtok(fileListFiles{sysnum},'_');
		fname = ['DataSet',fname];
		fname = fullfile(exptDir,fname);
		fprintf('Saving concatenated DataSet \n\tFilename: %s\n\tVariable Name: %s\n',...
				fname,datafilename);
		save(fname,'-struct','datafileoutput','-v6')
		datasetfilenames{sysnum} = fname;
end

if nargout>0
	varargout{1} = datasetfilenames;
end



