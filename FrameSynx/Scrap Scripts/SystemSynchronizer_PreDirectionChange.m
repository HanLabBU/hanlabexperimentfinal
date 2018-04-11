classdef SystemSynchronizer < hgsetget
		
		
		
		
		
		
		
		properties
				experimentSyncObj
				trialSyncObj
				frameSyncObj
		end
		properties (SetAccess = protected)
				behaviorSystemObjects
				cameraSystemObjects
		end
		properties (Hidden)
				allSubSystemObjects
				experimentSyncListener
				trialSyncListener
				frameSyncListener
				default
		end
		properties
				setting
		end
		
		
		
		
		
		
		methods % SETUP
				function obj = SystemSynchronizer(varargin)
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end
						end
						obj.defineDefaults();
						obj.checkProperties();
				end
				function defineDefaults(obj)
						obj.default = struct.empty(0,1);
						
				end
				function checkProperties(obj)
						props = properties(obj);
						for n = 1:length(props)
								prop = props{n};
								if isempty(obj.(prop)) && isfield(obj.default,prop)
										obj.(prop) = obj.default.(prop);
								end
						end
						if isempty(obj.behaviorSystemObjects)
								obj.behaviorSystemObjects = BehaviorSystem.empty(0,1);
						end
						if isempty(obj.cameraSystemObjects)
								obj.cameraSystemObjects = CameraSystem.empty(0,1);
						end
						if isempty(obj.allSubSystemObjects)
								obj.allSubSystemObjects = cell.empty(0,1);
						end
				end
		end
		methods % USER FUNCTIONS
				function register(obj,subSystemObj,varargin)
						switch class(subSystemObj)
								case 'BehaviorSystem'
										if ~any(obj.behaviorSystemObjects == subSystemObj)
												obj.behaviorSystemObjects(numel(obj.behaviorSystemObjects )+1) = subSystemObj;
												obj.allSubSystemObjects{numel(obj.allSubSystemObjects)+1} = subSystemObj;
										end
								case 'CameraSystem'
										if ~any(obj.cameraSystemObjects == subSystemObj)
												obj.cameraSystemObjects(numel(obj.cameraSystemObjects)+1) = subSystemObj;
												obj.allSubSystemObjects{numel(obj.allSubSystemObjects)+1} = subSystemObj;
										end
						end
						if nargin > 2 % (sync arguments)
								for n = 1:numel(varargin)
										switch lower(varargin{n})
												case 'experiment'
														obj.experimentSyncObj =  subSystemObj;
												case 'trial'
														obj.trialSyncObj = subSystemObj;
												case 'frame'
														obj.frameSyncObj = subSystemObj;
												otherwise
														warning('SystemSynchronizer:register:InvalidSyncArgument',...
																'Synchronization argument (%s) invalid: use ''experiment'' ''trial'' or ''frame''.\n',...
																varargin{n});
										end
								end
						end
				end
		end
		methods % SET
				function set.experimentSyncObj(obj,syncsystem)
						if ~any(strcmp(events(syncsystem),'ExperimentStart'))
								warning('SystemSynchronizer:set_experimentSyncObj:MissingExperimentEvent',...
										'The assigned experimentSync object should have an ExperimentStart event');
						end
						obj.experimentSyncObj = syncsystem;
						if ~isempty(obj.allSubSystemObjects)
								sys = obj.allSubSystemObjects(obj.allSubSystemObjects ~= syncsystem);
								set(sys,'experimentSyncObj',syncsystem);
						end
				end
				function set.trialSyncObj(obj,syncsystem)
						if ~any(strcmp(events(syncsystem),'NewTrial')) ...
										&& ~any(strcmp(events(syncsystem),'TrialStart'))
								warning('SystemSynchronizer:set_trialSyncObj:MissingTrialEvent',...
										'The assigned trialSync object should have a NewTrial or a TrialStart event');
						end
						obj.trialSyncObj = syncsystem;
						if ~isempty(obj.allSubSystemObjects)
								sys = obj.allSubSystemObjects(obj.allSubSystemObjects ~= syncsystem);
								set(sys,'trialSyncObj',syncsystem);
						end
				end
				function set.frameSyncObj(obj,syncsystem)
						
				end
		end
		methods % CLEANUP
				function delete(obj)
						if ~isempty(obj.currentDataFile) && isopen(obj.currentDataFile)
								closeFile(obj.currentDataFile);
						end
						if ~isempty(obj.currentDataFile) ...
										&& isopen(obj.currentDataFile) ...
										&& ~issaved(obj.currentDataFile)
								obj.saveDataFile;
						end
				end
		end
		
		
		
		
		
		
		
end













