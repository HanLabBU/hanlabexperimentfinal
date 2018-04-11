classdef VideoFile < handle
		
		
		
		properties % settings
				vidFilePath
				vidSize
				vidDimensions
				vidDataType
				frameFrequency
		end
		properties % variables
				fileID
		end
		properties % data
				time
				meta
		end
		properties (Dependent, SetAccess = protected)
				vid
		end
		properties (Access = protected)
				
		end
		
		
		
		methods
				function obj = VideoFile(varargin)
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end
						end
						checkProperties(obj);
				end
				function checkProperties(obj)
						default.vidFilePath =  fullfile('Z:\',...
								['VideoFile_',datestr(now,'mmmdd_HHMMSS'),'.buk']);
						default.vidSize = [256 256 1 0];
						default.vidDimensions = 4;
						default.vidDataType = 'uint16';
						default.frameFrequency = 1;
						propnames = fields(default);
						for n = 1:length(propnames)
								if isempty(obj.(propnames{n}))
										obj.(propnames{n}) = default.(propnames{n});
								end
						end
				end
				function openNewFile(obj)
						obj.fileID = fopen(obj.vidFilePath,'wb');
						fwrite(obj.fileID,[obj.vidDimensions,obj.vidSize],'uint16');
				end
		end
		
		
		
		
		
end






