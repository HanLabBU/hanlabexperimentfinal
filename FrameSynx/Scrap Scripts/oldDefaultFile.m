classdef DefaultFile < hgsetget & dynamicprops
		
		
		
		
		
		properties (SetObservable, Hidden)
				className
				textFileName
				textFileDirectory
				dynamicPropMeta
				hardCodeDefault
		end
		
		
		
		
		
		
		
		methods
				function obj = DefaultFile(varargin)
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end
						end
						if isempty(obj.className)
								obj.className = 'UnkownClass';
						end
						if isempty(obj.textFileName)
								obj.textFileName = [obj.className,'_Settings.txt'];
						end
						if isempty(obj.textFileDirectory)
								try
										fpath = fullfile(imaqroot,'Settings');
								catch
										fpath = fullfile(fileparts(which('ImageAcquisitionGUI')),'Settings');
								end
								if ~isdir(fpath)
										if ~mkdir(fpath)
												fpath = pwd;
												warning('DefaultFile:textFileDirectory',...
														['Text file will be saved to: ',fpath]);
										end
								end
								obj.textFileDirectory = fpath;
						end
				end
		end
		methods (Hidden)
				function checkFile(obj)
						if exist(fullfile(obj.textFileDirectory,obj.textFileName),'file') ~= 2 % file does not exist
								if exist(obj.textFileName,'file') == 2
										obj.textFileDirectory = fileparts(which(obj.textFileName));
										msgbox([obj.className,...
												' will use default settings from the file: ',...
												fullfile(obj.textFileDirectory,obj.textFileName)],...
												'Defaults-File Not in Normal Folder');
								else % no file exists in matlab path
										userinput = questdlg(...
												['Locate the settings file or create a new file for: ',obj.className],...
												'Default Settings File Not Found',...
												'Locate','Create New','Create New');
										switch lower(userinput(1:6))
												case 'locate'
														[fname,pathname] = uigetfile('.txt',...
																['Locate ',obj.className,' Default Settings File']);
														if fname ~= 0
																obj.textFileName = fname;
																obj.textFilePath = pathname;
																addpath(obj.textFilePath,'-end');
																savepath;
														else
																createNewFile(obj)
														end
												case 'create'
														createNewFile(obj)
										end
								end
						end
% 						disp([obj.className,' settings specified from: '])
% 						disp(fullfile(obj.textFileDirectory,obj.textFileName))
				end
				function createNewFile(obj)
						if ~isdir(obj.textFileDirectory)
								obj.textFileDirectory = fullfile(which('ImaqeAcquisitionGUI'),'Settings');
								[fname,pathname] = uiputfile('.txt',...
										['Create Default Settings File for: ',obj.className],...
										fullfile(obj.textFileDirectory,obj.textFileName));
								obj.textFileDirectory = pathname;
								obj.textFileName = fname;
						end
						if ~isempty(fields(obj.hardCodeDefault))
								prompt = fields(obj.hardCodeDefault);
								title = [obj.className,' Settings'];
								defs = struct2cell(obj.hardCodeDefault);
								for n = 1:length(defs) % make sure pre-defaults are strings
										setval = defs{n};
										switch class(setval)
												case 'char'
												case {'double','logical'}
														setval = num2str(setval);
												case 'function_handle'
														setval = char(setval);
												case 'cell'
														setval = sprintf('%s,',setval{:});
												case 'struct'
														%TODO:?
												otherwise
														setval = char(setval);
										end
										defs{n} = setval;
								end
								inputoptions = struct(...
										'Resize','on',...
										'WindowStyle','normal',...
										'Interpreter','tex');
								answer = inputdlg(prompt,title,1,defs,inputoptions);
								obj.hardCodeDefault = cell2struct(answer,prompt,1);
								writeFile(obj)
						else
								warning('DefaultFile:CreateNewFile','Settings structure is empty');
						end
				end
				function writeFile(obj) % write file from settings structure
						fid = fopen(fullfile(obj.textFileDirectory,obj.textFileName),'w+t');
						propname = fields(obj.hardCodeDefault);
						propval = struct2cell(obj.hardCodeDefault);
						for n = 1:length(propname)
								fprintf(fid,'%s:%s\n',propname{n},propval{n})
						end
						fclose(fid);
				end
				function readFile(obj)
						% 						[propnames,valstrings] = textread(obj.textFileName,'%s %s','delimiter',':');
						textlines = textread(obj.textFileName,'%s','delimiter','\n');
						[propnames, valstrings] = strtok(textlines,': ');
						[valstrings, postcolon] = strtok(valstrings,': ');
						for n = 1:length(postcolon)
								if ~isempty(postcolon)
										% In case of file paths with colons in them
										valstrings{n} = cat(2,valstrings{n},postcolon{n});
								end
						end
						if length(propnames) ~=length(valstrings)
								warning('DefaultFile:readFile',...
										['Number property and value pairs do not match in file: ',obj.textFileName])
								return
						end
						currentprops = properties(obj);
						for n = 1:length(propnames) % read each line and create new property or set value
								if isempty(strfind(currentprops,propnames{n}))
										obj.dynamicPropMeta.(propnames{n}) = addprop(obj,propnames{n});
								end
								if ~isempty(valstrings{n})
										obj.(propnames{n}) = valstrings{n};
								end
						end
				end % create actual properties from file
		end

		
		
		
end



