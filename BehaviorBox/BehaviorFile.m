classdef BehaviorFile < DataFile
		

		
		
				
		properties (SetObservable, GetObservable, AbortSet)% Header Data
% 				rootPath
% 				experimentName
% 				headerFileName
% 				dataFileName
% 				infoFileName
				stimNumber
				bhvControlComputerName
				trialNumber
% 				numFrames
% 				firstFrame
% 				lastFrame
% 				startTime
% 				dataType
		end
		properties (Hidden, SetAccess = protected)				
% 				headerFormat
% 				headerMapObj
% 				dataFileID %probably won't be used, but could be used to store eye data
% 				infoFileID
% 				infoFields
% 				infoFormat
% 				paddedProps
% 				filesOpen
% 				filesClosed
% 				default
		end
		
		
		
		
		
		
		
		methods % Constructor
				function obj = BehaviorFile(varargin)
						obj = obj@DataFile(varargin{:});
				end
		end
		methods (Hidden) % Initialization
				function defineDefaults(obj)
						obj.defineDefaults@DataFile;
						obj.default.stimNumber = NaN;						
						obj.default.experimentName = 'none';
						obj.default.bhvControlComputerName = 'nocomputername';
						obj.default.trialNumber = 0;
						obj.default.headerFileName =  ['BehaviorHeader_',datestr(obj.default.startTime,'yyyy_mm_dd_HHMMSS'),...
								sprintf('_N%i',obj.instanceNumber),'.fhf'];
						obj.default.dataFileName = ['BehaviorData_',datestr(obj.default.startTime,'yyyy_mm_dd_HHMMSS'),...
								sprintf('_N%i',obj.instanceNumber),'.fdf'];
						obj.default.infoFileName = ['BehaviorFrameInfo_',datestr(obj.default.startTime,'yyyy_mm_dd_HHMMSS'),...
								sprintf('_N%i',obj.instanceNumber),'.fif'];
				end
				function checkProperties(obj)
						% Add any property containing a variable length string to paddedProps
						obj.paddedProps = {...
								'experimentName',...
								'bhvControlComputerName'};
						obj.checkProperties@DataFile;
				end
		end
		methods % Functions for Saving
				function checkFrameInfo(obj,info)
						obj.checkFrameInfo@DataFile(info);
						% Check Stim Number						
						if isfield(info,'StimNumber')
								% assign stim number if it's not NaN, and if it has not been assigned before
								if isnan(obj.stimNumber) && ~isnan(info.StimNumber)
										obj.stimNumber = info.StimNumber;
								end
						end
				end
		end		
		methods % Cleanup and State-Check
				function delete(obj)
						obj.delete@DataFile;
				end
				function obj = saveobj(obj)
						obj = saveobj@DataFile(obj);
				end
		end
		methods (Static)
				function obj = loadobj(obj)
						obj = obj.loadobj@DataFile;
				end
		end
		
		
		
		
		
		
		
end








