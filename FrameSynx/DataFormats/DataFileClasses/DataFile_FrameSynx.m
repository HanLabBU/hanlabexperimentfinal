classdef DataFile < handle
		
		
		
		
		
		
		
		properties (SetObservable, GetObservable, AbortSet)% Header Data
				rootPath
				experimentName
				headerFileName
				dataFileName
				infoFileName
		end
		properties (SetObservable, GetObservable, AbortSet, SetAccess = protected)% Header Data
				numFrames
				firstFrame
				lastFrame
				startTime
				dataType
				dataSize
				instanceNumber
		end
		properties(Hidden,SetAccess = protected)
				headerFormat
				infoFormat
				infoFields
				paddedProps
				appendedDataFile
		end
		properties (Hidden, SetAccess = protected, Transient)
% 				headerMapObj
				dataFileID
				infoFileID
				filesOpen
				filesClosed
				fileSaved
				writingToFile
				fileFilled
				default
		end
		properties (Hidden, Transient) % File-Linking Properties
				nextDataFile
				previousDataFile
		end
		
		
		
		
		
		
		methods % Constructor
				function obj = DataFile(varargin)
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end
						end
						% Record Number of Calls to DataFile Constructor for File Labelling
						persistent DATAFILE_INSTANCE_NUMBER;
						if isempty(DATAFILE_INSTANCE_NUMBER)
								DATAFILE_INSTANCE_NUMBER = 1;
						else
								DATAFILE_INSTANCE_NUMBER = DATAFILE_INSTANCE_NUMBER+1;
						end
						obj.instanceNumber = DATAFILE_INSTANCE_NUMBER;
						obj.filesOpen = false;
						obj.filesClosed = false; % Both false -> fresh file
						obj.fileSaved = false;
						obj.writingToFile = false;
						obj.fileFilled = false;
						obj.defineDefaults;
						obj.checkProperties;
						obj.makeHeader;
						obj.makeListeners;
				end
		end
		methods (Hidden) % Initialization
				function defineDefaults(obj)
						global CURRENT_EXPERIMENT_NAME
						t = now;
						obj.default.rootPath = fullfile(['Z:\TEST\',...
								'TEST_',datestr(date,'yyyy_mm_dd')],...
								['ImagingData_',datestr(t,'yyyy_mm_dd')]);
						obj.default.experimentName = CURRENT_EXPERIMENT_NAME;
						obj.default.headerFileName =  ['FrameHeader_',datestr(t,'yyyy_mm_dd_HHMMSS'),...
								sprintf('_N%i',obj.instanceNumber),'.fhf'];%FrameHeaderFile
						obj.default.dataFileName = ['FrameData_',datestr(t,'yyyy_mm_dd_HHMMSS'),...
								sprintf('_N%i',obj.instanceNumber),'.fdf'];%FrameDataFile
						obj.default.infoFileName = ['FrameInfo_',datestr(t,'yyyy_mm_dd_HHMMSS'),...
								sprintf('_N%i',obj.instanceNumber),'.fif'];%FrameInfoFile
						obj.default.dataType = 'uint16';
						obj.default.dataSize = [0 0];
						obj.default.numFrames = 0;
						obj.default.firstFrame = 0;
						obj.default.lastFrame = 0;
						obj.default.startTime = t;
						if isempty(obj.default.experimentName)
								obj.default.experimentName = 'TEMP';
						end
				end
				function checkProperties(obj)
						padprops = {...
								'rootPath',...
								'experimentName',...
								'headerFileName',...
								'dataFileName',...
								'infoFileName',...
								'dataType'};
						obj.paddedProps = cat(2,padprops,obj.paddedProps);
						props = properties(obj); % hidden properties aren't seen
						for n=1:length(props)
								prop = props{n};
								if isfield(obj.default,prop)
										if isempty(obj.(prop))
												obj.(prop) = obj.default.(prop);
										else
												if ~strcmp(class(obj.(prop)), class(obj.default.(prop)))
														warning('DataFile:checkProperties:DefaultPropertyInvalidClass',...
																'Invalid Input to %s:\n\tClass of input should be %s, not %s\n',...
																prop, class(obj.default.(prop)), class(obj.(prop)));
												end
										end
								end
						end
						if ~isdir(obj.rootPath)
								mkdir(obj.rootPath)
						end
						if ~isdir(fullfile(obj.rootPath,'FrameSyncFiles'))
								mkdir(fullfile(obj.rootPath,'FrameSyncFiles'))
						end
				end
				function makeHeader(obj)
						fname = fullfile(obj.rootPath,'FrameSyncFiles',obj.headerFileName);
						[fid, message] = fopen(fname,'wb');
						if fid < 1
								error(message)
						end
						props = properties(obj);
						for n=1:length(props)
								prop = props{n};
								propclass = class(obj.(prop));
								val2write = obj.(prop);
								if any(strcmp(prop,obj.paddedProps))
										val2write = DataFile.pad(val2write,150);
								end
								if strcmp(propclass,'char')
										propclass = 'uint16';
										val2write = uint16(val2write);
								end % memmapfile doesn't take chars
								if isempty(obj.(prop))
										val2write = NaN;
								end
								try
										fwrite(fid, val2write, propclass);
								catch me
										disp(me.stack(1))
										warning(me.message);
								end
								obj.headerFormat{n,1} = propclass;
								obj.headerFormat{n,2} = size(val2write);
								obj.headerFormat{n,3} = prop;
						end
						fclose(fid);
						% 						obj.headerMapObj = memmapfile(fname,...
						% 								'format',obj.headerFormat,...
						% 								'writable',true);
				end
				function makeListeners(obj)
						% 						props = properties(obj);
						% 						for n=1:length(props)
						% 								prop = props{n};
						% 								addlistener(obj,prop,'PostSet',@(src,evnt)propertyChangeFcn(obj,src,evnt));
						% 						end
				end
		end
		methods (Hidden) % Event Response
				function propertyChangeFcn(obj,src,~) % This Function is no long used.
						% Changes header file on disk (through memmapfile) whenever non-hidden properties are
						% changed
						% 						try
						% 								if ~isempty(obj.headerMapObj)
						% 										prop = src.Name;
						% 										val2write = obj.(prop);
						% 										% Pad Filenames
						% 										if any(strcmp(prop,obj.paddedProps))
						% 												val2write = DataFile.pad(val2write,150);
						% 										end
						% 										if ischar(val2write)
						% 												val2write = uint16(val2write);
						% 										end
						% 										if ~strcmp(class(obj.headerMapObj.Data.(prop)), class(val2write))
						% 												fprintf('HEADER CLASS MISMATCH\nProp: %s     headermap-class: %s    val2write-class: %s\n',...
						% 														prop,class(obj.headerMapObj.Data.(prop)),class(val2write))
						% 										elseif numel(obj.headerMapObj.Data.(prop)) ~= numel(val2write)
						% 												fprintf('HEADER NUMEL MISMATCH\nProp: %s     headermap-numel: %i    val2write-numel: %i\n',...
						% 														prop, numel(obj.headerMapObj.Data.(prop)) , numel(val2write))
						% 										else
						% 												obj.headerMapObj.Data.(prop) = val2write;
						% 										end
						% 								end
						% 						catch me
						% 								disp(me.stack(1))
						% 								warning(me.message)
						% 						end
				end
		end
		methods % Functions for Saving
				function openNewFile(obj)
						if obj.filesClosed
								error('DataFile:openNewFile:FileClosed',...
										'This file has already been written, further writes will overwrite data.')
						end
						obj.dataFileID = fopen(fullfile(obj.rootPath,'FrameSyncFiles',obj.dataFileName),'wb');
						obj.infoFileID = fopen(fullfile(obj.rootPath,'FrameSyncFiles',obj.infoFileName),'wb');
						if obj.infoFileID < 1  ||  obj.dataFileID < 1
								error('error opening data and info files')
						end
						obj.filesOpen = true;
				end
				function addFrame2File(obj,data,info,varargin)
						if nargin > 3
								% Assign Option for 3rd Dimension in Data if Applicable
								multiChannelOption = varargin{1};
						else
								multiChannelOption = 'unspecified';
						end
						try
								obj.writingToFile = true;
								if ~obj.isopen && ~obj.isclosed
										% Fresh object -> needs to be opened, has NOT been filled and closed
										openNewFile(obj)
								end
								% If Multiple Frames are attempted, Go Recursive
								switch ndims(data)
										case 4 % Split Frames and Call Recursively (Won't work unless info is same size as data)
												fieldname = fields(info);
												for n=1:size(data,4)
														for m = 1:length(fieldname)
																subinfo.(fieldname{m}) = info.(fieldname{m})(n);
														end
														obj.addFrame2File(squeeze(squeeze(data(:,:,1,n))),subinfo)
												end
										case 3 % Handle Multiple Channels of Data
												% Assume 3rd Dimension is Color and Sum Frames												
												switch lower(multiChannelOption)
														case 'sum' % meant for rgb2bw
																obj.addFrame2File(uint16(sum(data,3)),info)
														case 'luminance' % for YCbCr from NTSC source
																obj.addFrame2File(uint8(data(:,:,1)),info);
														otherwise
																obj.addFrame2File(uint8(data(:,:,1)),info);
												end
										case {2,1} % Normal Case (Single Frame)
												% Update Header
												obj.numFrames = obj.numFrames + 1;
												% Update DataSize, DataType, etc.
												obj.dataSize = size(data);
												obj.dataType = class(data);
												% Write DATA to Data File
												if ~isempty(data)
														if ~isempty(fopen(obj.dataFileID))
																fwrite(obj.dataFileID,data(:),obj.dataType);
														else
																warning('DataFile:checkFrameInfo:DataFileClosed',...
																				'The Data file has been closed for class: %s',class(obj));
														end
												end
												% Write INFO to Info File
												if ~isempty(info)
														% Record Frame INFO Format (if first frame)
														if isempty(obj.infoFields)
																obj.infoFields =  fields(info);
																for n=1:length(obj.infoFields)
																		prop = obj.infoFields{n};
																		propclass = class(info.(prop));
																		obj.infoFormat{n,1} = propclass;
																		obj.infoFormat{n,2} = size(info.(prop));
																		obj.infoFormat{n,3} = prop;
																end
														end
														% Write All Frame INFO to File
														vec2write = zeros(length(obj.infoFields),1);
														for n = 1:length(obj.infoFields)
																infobit = info.(obj.infoFields{n});
																if isempty(infobit)
																		infobit = NaN;
																end
																vec2write(n) = double(infobit);
														end
														try
																if ~isempty(fopen(obj.infoFileID))
																		fwrite(obj.infoFileID,vec2write(:),'double');
																else
																		warning('DataFile:checkFrameInfo:InfoFileClosed',...
																				'The Info file has been closed for class: %s',class(obj));
																		try
																				addFrame2File(obj.nextFile,data,info);
																				fprintf('Write to next file successful\n');
																		catch
																				fprintf('Write to closed file NOT successful\n');
																		end
																end
														catch me
																disp(me.stack(1))
																warning(me.message);
														end
														% Extract Data from INFO Structure
														obj.checkFrameInfo(info);
												end
								end
								obj.writingToFile = false;
								obj.fileFilled = true;
						catch me
								warning(me.message)
								disp(me.stack(1));
						end
				end
				function checkFrameInfo(obj,info)
						if ~isempty(info)
						% Update Frame-Number Info - Keep First/Last Frame-Numbers Current
								if obj.firstFrame == 0
										if isfield(info,'FrameNumber')
												obj.firstFrame = info.FrameNumber;
										else
												obj.firstFrame = 1;
										end
								end
								if isfield(info,'FrameNumber')
										obj.lastFrame = info.FrameNumber;
								else
										obj.lastFrame = obj.numFrames;
								end
						elseif obj.firstFrame == 0
								% Manual Info Recording
								obj.firstFrame = 1;
								obj.lastFrame = 1;
						else
								obj.lastFrame = obj.numFrames;
						end
				end
				function closeFile(obj) % call at the end of a trial
						if isopen(obj)
								tic
								while toc < .5
										if obj.iswriting
												% 												pause(.01);
												% 												fprintf('DataFile attempting to close while
												% 												writing: %i\n',toc);
												fmu = imaqmem('FrameMemoryUsed') ;
												if fmu > 250e6 % 250MB
														warning('DataFile:closeFile',...
																'Frame Memory has reached %i while attempting to close a file',fmu);
														break
												end
												pause(.01);
										else
												break
										end
								end
								fclose(obj.dataFileID);
								fclose(obj.infoFileID);
								obj.makeHeader;% Added this after getting rid of memmapfile
						end
						obj.filesOpen = false;
						obj.filesClosed = true;
				end
		end
		methods % Functions for Retrieving Data				
				function varargout = getData(obj,varargin)
					dbstop if error
						% USAGE:
						% --------------------------------------------------------------------------------------
						% Input (obj)
						% -> any object of the DataFile class or derivative (VideoFile, BehaviorFile) 						
						% or any array of DataFile objects
						% --------------------------------------------------------------------------------------
						% Examples:
						% data = obj.getData('arg1','arg2',...)   OR data = getData(obj,'arg1','arg2',...)
						% data = getData(obj) -> returns all data in all input videofiles
						% data = getData(obj,'all') -> also returns all data
						% data = getData(obj, 1:10 )  -> returns first 10 frames of each videofile (trial relative)
						% data = getData(obj, 'Channel','r')  -> returns all red frames
						% data = getData(obj,'FrameNumber',5:10:100) -> call using any field in info struct
						% [data info] = getData(obj, 'Channel','r') -> info structure is also scalar/concatenated
						% --------------------------------------------------------------------------------------
						
						% If Method Called on a DataFile Array -> Call Recursively
						if length(obj) > 1
								if length(obj) > get(0,'RecursionLimit')
										set(0,'RecursionLimit',length(obj)+10)
								end
								obj = obj(:);
								try
										rec_data = getData(obj(2:end),varargin{:});
										if ~isempty(rec_data)
												data = cat(4,getData(obj(1),varargin{:}),rec_data);
										else
												data = getData(obj(1),varargin{:});
										end
% 										data = cat(4,getData(obj(1),varargin{:}),getData(obj(2:end),varargin{:}));
								catch me
										data = [];
										warning('DataFile:getData:DataRetrievalError',...
												'Data retrieval failed for from the Data-File named: %s\n%s\n',...
												obj(1).dataFileName,me.message);
								end
								varargout{1} = data;
								if nargout>1 % Return Info Structure (concatenated)
										infoT = obj.getInfo(varargin{:});
										fld = fields(infoT);
										for n = 1:numel(fld)
												info.(fld{n}) = cat(1,infoT.(fld{n}));
										end
										varargout{2} = info;
								end
								return
						end
						% NON-RECURSIVE SECTION ----> START OF FUNCTION HERE
						if obj.numFrames ==0
							if nargout>0
								varargout{1} = [];
								if nargout>1
									varargout{2} = [];
								end
							end
							return
						end
						info = obj.getInfo(varargin{:});
						% Get Frame Numbers from Arguments
						try
							frames = obj.getFrames(varargin{:});
						catch me
							beep
							keyboard
						end
						% Read Data from File (if necessary)
						if ~isempty(frames)
						if isopen(obj)
								closeFile(obj)
						end
						[fid,message] = fopen(fullfile(obj.rootPath,'FrameSyncFiles',obj.dataFileName),'r');
						if fid < 1
								[fid,message] = fopen(fullfile('.','FrameSyncFiles',obj.dataFileName),'r');
								if fid < 1
										if exist(fullfile(obj.rootPath,obj.infoFileName),'file') % old format, should recover manually instead
												[fid,message] = fopen(fullfile(obj.rootPath,obj.dataFileName),'r');
										else
												obj.setNewRootPath();
												return
										end
								end
						end
						output = fread(fid,prod([obj.dataSize obj.numFrames]),['*',obj.dataType]);
						try
						output = reshape(output,obj.dataSize(1),obj.dataSize(2),1,[]);
						fclose(fid);
						output = output(:,:,:,frames);
						catch me
							frames = intersect(frames,1:size(output,4));
							output = output(:,:,:,frames);
						end
						else
								output = [];
						end
						varargout{1} = output;
						if nargout > 1
								fld = fields(info);
								% Manage missed frames (short info struct)
								% 								if frames(end) > length(info.(fld{1}))
								% 										missingframe = find(frames <= length(info.(fld{1})),1,'last');
								% 										missingframe = num2str(info.FrameNumber(missingframe));
								% 										frames = frames(1:length(info.(fld{1})));
								% 										warning('DataFile:getFrames:MissingFrames',...
								% 												'Missing frames after frame # %s',missingframe);
								% 								end
								varargout{2} = info;
								% 								for n = 1:length(fld)
								% 										frameinfo.(fld{n}) = info.(fld{n})(frames);
								% 								end
								% 								varargout{2} = frameinfo;

						end
				end
				function output = getInfo(obj,varargin)
						% obj.getInfo('cat','arg1','arg2',...) returns concatenated info-structure
						output = [];
						% Call getInfo Recursively if Given Array Input
						if length(obj) > 1
								if length(obj) > get(0,'RecursionLimit')
										set(0,'RecursionLimit',length(obj)+10)
								end
								obj = obj(:);
								if nargin >= 2 && strcmpi(varargin{1},'cat')
										args = varargin(2:end);
										output = cat(1,getInfo(obj(1),args{:}),getInfo(obj(2:end),args{:}));
										% Return Info Structure (concatenated)
										fld = fields(output);
										for n = 1:numel(fld)
												infocat.(fld{n}) = cat(1,output.(fld{n}));
										end
										output = infocat;
								else
										try
												output = cat(1,getInfo(obj(1),varargin{:}),getInfo(obj(2:end),varargin{:}));
										catch me
												keyboard
										end
								end
								return
						end
						% Normal (non-recursive) Function Body
						if isopen(obj)
								closeFile(obj)
						end
						% Attempt to Locate Data and Info Sub-Files
						fname = fullfile(obj.rootPath,'FrameSyncFiles',obj.infoFileName);
						if ~exist(fname,'file')
								fname = fullfile('.','FrameSyncFiles',obj.infoFileName);
						end
						if ~exist(fname,'file')
								if obj.numFrames < 1
										output = [];
										return
								end
						end
						[fid,message] = fopen(fname,'r');
						if fid < 1
								if exist(fullfile(obj.rootPath,obj.infoFileName),'file')
										[fid,~] = fopen(fullfile('.','FrameSyncFiles',obj.infoFileName),'r');
								else
										output = -1;
										error(message)
								end
						end
						info = fread(fid,prod([length(obj.infoFields),obj.numFrames]),'double');
						fclose(fid);
						nfields = length(obj.infoFields);
						for n = 1:nfields
								if strcmp(obj.infoFormat{n,1},'char')
										output.(obj.infoFields{n}) = char(info(n:nfields:end));
								else
										output.(obj.infoFields{n}) = info(n:nfields:end);
								end
						end
						if nargin > 2
								% Select Frames from Each File/Trial
								frames = obj.getFrames(varargin{:});
								output = structfun(@(s) s(frames), output, 'UniformOutput',false);
						end
				end
				function output = getFrames(obj,varargin)
						info = obj.getInfo;
						if ~isstruct(info)
								fprintf('Problem retrieving data\n')
								return
						end
						% Handle Calls with Data-File Array
							if length(obj) > 1
								if length(obj) > get(0,'RecursionLimit')
										set(0,'RecursionLimit',length(obj)+10)
								end
								obj = obj(:);
								output = cat(1,{getFrames(obj(1),varargin{:})},getFrames(obj(2:end),varargin{:}));
								return
						end
						
						frameset = cell.empty(0,1);
						m=1;
						% Argument Case 1 - All Frames -> getFrames(obj)  or  getFrames(obj,'all')
						if nargin == 1 || any(strcmpi(varargin{1},'all'))
								frameset{1} = 1:obj.numFrames;% TODO: change so frames can be extracted from an array of files
						else
								% Argument Case 2 - Numbered Frames ->  getFrames(obj,1:60)
								if isnumeric(varargin{1})
										frameset{1} = varargin{1};
										m=2;
										firstarg = 2;
								else
										firstarg = 1;
								end
								% Argument Case 3 - Criteria-Value Paired Frames
								%       (criteria: TrialNumber, Channel, StimNumber, StimStatus)
								%       ->   getFrames(obj,'Channel','r')
								if nargin > 2
										for n = firstarg:2:nargin-1
												infoname = varargin{n};
												infoval = varargin{n+1};
												if ischar(infoname)
														% Return Frames with Info Values
														if isfield(info,infoname)
																frameset{m} = find(ismember(double(info.(infoname)(:)') , double(infoval)));
																m=m+1;
														end
												end
										end
								end
						end
						if length(frameset) > 1
								frames = intersect(frameset{:});
						elseif length(frameset) ==1
								frames = frameset{1};
						else
								frames = [];
						end
						% Restrict Frames to those in a set only
						output = frames;
				end
				function setNewRootPath(obj)
						persistent DATAFILE_ROOTPATH
						obj.rootPath = DATAFILE_ROOTPATH;
						if isempty(obj.rootPath) || ~isdir(obj.rootPath)
								obj.rootPath = uigetdir(pwd,...
										'Locate the experiment folder containing the folder: FrameSyncFiles','Set Root-Path');
								errordlg('Root-Path is wrong: Set a new path to the experiment',...
										'Experiment-Path Not Found','modal');
						end
						DATAFILE_ROOTPATH = obj.rootPath;
				end
		end
		methods % Cleanup and State-Check
				function bool = isopen(obj)
						bool = obj.filesOpen;
						if bool
								openfiles = fopen('all');
								if ~any(openfiles==obj.dataFileID) || ~any(openfiles==obj.infoFileID)
										bool = false;
								end
						end
						if isempty(bool)
								bool = false;
						end
				end
				function bool = isclosed(obj)
						bool = obj.filesClosed;
				end
				function bool = issaved(obj)
						if ~isempty(obj.fileSaved)
								bool = obj.fileSaved;
						else
								bool = false;
						end
				end
				function bool = iswriting(obj)
						bool = obj.writingToFile;
				end
				function delete(obj)
% 						clear obj.headerMapObj
						closeFile(obj)
				end
				function obj = saveobj(obj)
						if ~isclosed(obj)
								obj.closeFile;
						end
						% 						fprintf('%s Saved\n',class(obj));
						obj.fileSaved = true;
				end
		end
		methods (Static)
				function padded_string = pad(str,desired_length)
						n_spaces = desired_length-length(str);
						padded_string = [str, repmat(' ',[1 n_spaces])];
				end
				function obj = loadobj(obj)
						
				end
		end
		
		
		
		
end

%TODO: add a timer or something to update header? or protect from others?

% info structure passed to addFrame2File should have the following fields:
% {FrameNumber, Channel,






















