function varargout = findAndReplaceAcrossFiles(varargin)
if isdir('C:\Users\monkey\Documents\MATLAB\ImageAcuisitionCurrent')
		startdir = 'C:\Users\monkey\Documents\MATLAB\ImageAcuisitionCurrent';
else
		startdir = pwd;
end
projectDirectory = uigetdir(startdir,'Set Directory');
contents = dir(projectDirectory);
contents = contents([contents.isdir]);
options.WindowStyle = 'normal';
str = inputdlg({'Find','Replace With'},'Find and Replace',1,{'',''},options);
directories = struct;
repeatmode = true;
while ~isempty(str)
		oldword = ['\<',str{1},'\>'];
		newword = str{2};
		% Go through directories
		for m = 1:length(contents)
				if strcmp(contents(m).name,'..')
						continue
				end
				if strcmp(contents(m).name,'.')
						[~, dirname] = fileparts(projectDirectory);
						subDirectory = dirname;
				else
						subDirectory = contents(m).name;
				end
				dirname = strtok(subDirectory(~isspace(subDirectory)),'.');
				directories.(sprintf('%s',dirname)) = subdirfcn(subDirectory);
		end
		if repeatmode
				str = inputdlg({'Find','Replace With'});
		else
				str = {};
		end
end
if nargout > 0;
		varargout{1} = directories;
end

		function subfiles = subdirfcn(subDirectory)
				subfiles = struct;
				files = what(subDirectory);
				if isdir(subDirectory)
						mfiles = files.m;
				else
						mfiles{1} = subDirectory;
						files(1).path = projectDirectory;
				end
				for n = 1:length(mfiles);
						afile = fullfile(files.path,mfiles{n});
						filename = strtok(mfiles{n},'.');
						fid = fopen(afile);
						txt = textscan(fid,'%s','delimiter','\n','whitespace','');
						fclose(fid);
						txt = txt{1};
% 						subfiles.(sprintf('%s',filename)) = regexp(txt,oldword,'match');
						txt = regexprep(txt,oldword,newword,'warnings');
						subfiles.(sprintf('%s',filename)) = txt;
						fid = fopen(afile,'w+');
						fprintf(fid,'%s\n',txt{:});
						fclose(fid);
				end
		end

end
