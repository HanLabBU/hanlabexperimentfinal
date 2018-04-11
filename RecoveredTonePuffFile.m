classdef RecoveredTonePuffFile < DataFile
		

		
		
				
		properties (SetObservable, GetObservable, AbortSet)% Header Data
% 				rootPath
% 				experimentName
% 				headerFileName
% 				dataFileName
% 				infoFileName
				stimulusNumber				
				trialNumber
				numChannels = 1
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
		properties % Recovery
		   
		end
		
		
		
		
		
		
		
		methods % Constructor
				function obj = RecoveredTonePuffFile(varargin)
				   [tphName, tphDir] = uigetfile('*.fhf','Select a Header File to Recover','MultiSelect','on')
				   
				end
		end
		methods (Hidden) % Initialization
				function defineDefaults(obj)
						obj.defineDefaults@DataFile;			
						obj.default.experimentName = 'TonePuffExperiment';
						obj.default.trialNumber = 0;
						obj.default.headerFileName =  ['TonePuffHeader_',datestr(obj.default.startTime,'yyyy_mm_dd_HHMMSS'),...
								sprintf('_N%i',obj.instanceNumber),'.fhf'];
						obj.default.dataFileName = ['TonePuffData_',datestr(obj.default.startTime,'yyyy_mm_dd_HHMMSS'),...
								sprintf('_N%i',obj.instanceNumber),'.fdf'];
						obj.default.infoFileName = ['TonePuffFrameInfo_',datestr(obj.default.startTime,'yyyy_mm_dd_HHMMSS'),...
								sprintf('_N%i',obj.instanceNumber),'.fif'];
				end
				function checkProperties(obj)
						% Add any property containing a variable length string to paddedProps
						obj.paddedProps = {...
								'experimentName'};
						obj.checkProperties@DataFile;
				end
		end
		methods % Functions for Saving
				function checkFrameInfo(obj,info)
						obj.checkFrameInfo@DataFile(info);						
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








