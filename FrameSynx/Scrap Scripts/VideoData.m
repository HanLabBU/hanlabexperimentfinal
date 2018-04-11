classdef VideoData < handle
		
		
		
		properties (SetObservable, GetObservable)% Header Data
				rootPath
				headerFileName
				dataFileName
				infoFileName
				dataType
				bitDepth
				resolution
				numChannels
				numFrames
				firstFrame
				lastFrame
				startTime
				channelSequence
		end
		properties (Hidden)
				frame				
		end
		properties (Hidden, SetAccess = protected)				
				headerFormat
				headerMapObj
				dataFileID
				infoFileID
		end
		
		
		
		
		methods % Constructor
				function obj = VideoData(varargin)
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end
						end
% 						obj.frame = FrameData.empty(1000,0);
						obj.checkProperties;
						obj.makeHeader;
						obj.makeListeners;
				end
		end
		methods (Hidden) % Initialization
				function checkProperties(obj)
						t = now;
						default.rootPath = 'Z:\';
						default.headerFileName =  ['VideoHeader_',datestr(t,'yyyy_mm_dd_HHMMSS'),'.vhf'];
						default.dataFileName = ['VideoData_',datestr(t,'yyyy_mm_dd_HHMMSS'),'.vdf'];
						default.infoFileName = ['VideoFrameInfo_',datestr(t,'yyyy_mm_dd_HHMMSS'),'.vif'];
						default.dataType = 'uint16';
						default.bitDepth = 16;
						default.resolution = [256 256];
						default.numChannels = 1;
						default.numFrames = 1000;
						default.firstFrame = 1;
						default.lastFrame = 1000;
						default.startTime = now;
						default.channelSequence = 'r';
						props = properties('VideoData'); % hidden properties aren't seen
						for n=1:length(props)
								if isempty(obj.(props{n}))
										obj.(props{n}) = default.(props{n});
								else
										if ~strcmp(class(obj.(props{n})), class(default.(props{n})))
												error('Invalid Input')
										end
								end
						end
				end
				function makeHeader(obj)
						fname = fullfile(obj.rootPath,obj.headerFileName);
						[fid, message] = fopen(fname,'wb');
						if fid < 1
								error(message)
						end								
						props = properties('VideoData');
						for n=1:length(props)
								prop = props{n};
								propclass = class(obj.(prop));
								if strcmp(propclass,'char')
										propclass = 'uint16';
								end % memmapfile doesn't take chars
								fwrite(fid, obj.(prop), propclass);
								obj.headerFormat{n,1} = propclass;
								obj.headerFormat{n,2} = size(obj.(prop));
								obj.headerFormat{n,3} = prop;
						end
						fclose(fid);
						obj.headerMapObj = memmapfile(fname,...
								'format',obj.headerFormat,...
								'writable',true);
				end
				function makeListeners(obj)
						props = properties('VideoData');
						for n=1:length(props)
								prop = props{n};
								addlistener(obj,prop,'PostSet',@(src,evnt)propertyChangeFcn(obj,src,evnt));								
						end
				end
		end
		methods (Hidden) %Event Response
				function propertyChangeFcn(obj,src,~)
						if ~isempty(obj.headerMapObj)
								prop = src.Name;
								obj.headerMapObj.Data.(prop) = obj.(prop);
						end
				end
		end
		methods % User Functions
				function openNewDataFile(obj)
						obj.dataFileID = fopen(fullfile(obj.rootPath,obj.dataFileName),'wb');
						obj.infoFileID = fopen(fullfile(obj.rootPath,obj.infoFileName),'wb');
				end
				function addData2File(obj,data,info)
						fwrite(obj.dataFileID,data(:),obj.dataType);
						if ~isempty(info)
								infoFields = fields(info);
								for n = 1:length(infoFields)
										fwrite(obj.infoFileID, double(info.(infoFields{n})), 'double')
								end
						end
				end
				
		end		
		methods % Cleanup
				function delete(obj)
						clear obj.headerMapObj
				end
		end
end

%TODO: add a timer or something to update header? or protect from others?









