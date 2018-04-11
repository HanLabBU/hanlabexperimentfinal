classdef BehaviorSystem < SubSystem
		
		
		
		
		
		
		
		properties
				experimentSyncObj
				trialSyncObj
				frameSyncObj
		end
		properties
				stimulusPresentationObj
				stimulusPresentationObjProperties
				% 		currentDataFile
				% 		sessionPath
				% 		currentExperimentName
				% 		systemName
				% 		savedDataFiles
				% 		currentDataSetPath
				% 		saveSetting
				% 		autoSaveFrequency
		end
		properties (Hidden)
				cameraTriggeredFramesAcquired
				cameraObj
				% 		frameSyncListener
				% 		experimentStateListener
				% 		trialStateListener
				% 		framesAcquired
				% 		nDataFiles
				% 		experimentRunning
		end
		
		
		
		events
				ExperimentStart
				ExperimentStop
				NewTrial
				NewStimulus
		end
		
		
		
		
		methods %CONTROL
				function obj = BehaviorSystem(varargin)
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end
						end
						obj.checkProperties
						obj.createSystemComponents
				end
				function defineDefaults(obj)
					persistent bhvnum
					if isempty(bhvnum)
						bhvnum = 1;
					else
						bhvnum = bhvnum+1;
					end
						obj.defineDefaults@SubSystem;
						obj.default.systemName =  ['BehaviorSystem_',num2str(bhvnum)];
				end
				function checkProperties(obj)
						obj.defineDefaults;
						obj.framesAcquired = 0;
						obj.cameraTriggeredFramesAcquired = 0;
						obj.experimentRunning = false;
						obj.nDataFiles = 0;
						obj.savedDataFiles = BehaviorFile.empty(1,0);
						obj.currentDataFileSet = BehaviorFile.empty(1,0);
						obj.checkProperties@SubSystem;
				end
				function createSystemComponents(obj)
						% Start BehavControlInterface (StimulusPresentationInterface)
						if isempty(obj.stimulusPresentationObj) || ~isvalid(obj.stimulusPresentationObj)
								if ~isempty(obj.stimulusPresentationObjProperties)
										args = cat(2,fields(obj.stimulusPresentationObjProperties),...
												struct2cell(obj.stimulusPresentationObjProperties))';
										obj.stimulusPresentationObj = BehavControlInterface(args{:});
								else
										obj.stimulusPresentationObj = BehavControlInterface;
								end
						end
						% Listen to Changes in Trial Number and Experiment State from BehavCtrl
						if isempty(obj.experimentSyncObj) || ~isvalid(obj.experimentSyncObj)
								obj.experimentSyncObj = obj.stimulusPresentationObj;
						end
						if isempty(obj.trialSyncObj) || ~isvalid(obj.trialSyncObj)
								obj.trialSyncObj = obj.stimulusPresentationObj;
						end
						% Define Listener if frameSyncObj is available
						if ~isempty(obj.cameraObj)
								obj.frameSyncObj = obj.cameraObj; % for backwards compatibility -> remove eventually?
						end
						if ~isempty(obj.frameSyncObj)
								obj.frameSyncListener = addlistener(obj.frameSyncObj,...
										'FrameAcquired',@(src,evnt)frameAcquiredFcn(obj,src,evnt));
								obj.frameSyncListener.Enabled = false;
						end
				end
				function start(obj)
						if ~isdir(obj.sessionPath)
								mkdir(obj.sessionPath)
						end
						if isempty(obj.frameSyncListener)
								warning('BehaviorSystem:start:NoCameraListener',...
										'The Behavior-Control sysem is not connected to a camera, and will not record data every frame');
						else
								obj.frameSyncListener.Enabled = true;
						end
						obj.trialStateListener.Enabled = true;
						obj.experimentStateListener.Enabled = true;
						obj.ready = true;
						obj.cameraTriggeredFramesAcquired = 0;
						fprintf('BehaviorSystem ready... waiting for ExperimentStart event from BehavCtrl\n');
				end
				function trigger(obj)
						if ~isready(obj)
								obj.start();
						end
						obj.trialStateListener.Enabled = true;
						fprintf('Experiment Started\n');
						obj.experimentRunning = true;
						if ~isempty(obj.currentDataFileSet)
								obj.currentDataFileSet = BehaviorFile.empty(1,0);
								obj.nDataFiles = 0;
						end
						notify(obj,'ExperimentStart');
				end
				function stop(obj)
						if ~isempty(obj.frameSyncListener)
								obj.frameSyncListener.Enabled = false;
						end
						obj.trialStateListener.Enabled = false;
						obj.experimentStateListener.Enabled = false;
						if obj.experimentRunning
								notify(obj,'ExperimentStop');
								obj.experimentRunning = false;
								if ~isempty(obj.currentDataFile) ...
												&& isopen(obj.currentDataFile) ...
												&& ~issaved(obj.currentDataFile)
										obj.saveDataFile;
										obj.currentDataFile = BehaviorFile.empty(1,0);
								end
								obj.saveDataSet();
								obj.clearDataSet();
								fprintf('Experiment Stopped\n');
						end
				end
		end
		methods % EVENT RESPONSE
				function experimentStateChangeFcn(obj,src,evnt)
						global CURRENT_EXPERIMENT_NAME
						exptState = obj.stimulusPresentationObj.experimentState;
						if strcmp(evnt.EventName,'PostSet')
								% For Backwards Compatibility
								% If listeners are listening to property changes
								switch exptState
										case {'start exp','unpause'}
												if ~isdir(obj.sessionPath)
														mkdir(obj.sessionPath)
												end
												if ~obj.experimentRunning
														CURRENT_EXPERIMENT_NAME =  obj.stimulusPresentationObj.fileName(1:4);
														obj.updateExperimentName();
														obj.trigger();
												end
										case {'pause exp','finished'}
												CURRENT_EXPERIMENT_NAME = obj.currentExperimentName;
												obj.updateExperimentName();
												obj.stop();
								end
						else
								% If listeners are listening to another BehaviorSystem
								switch evnt.EventName
										case 'ExperimentStart'
												if ~isdir(obj.sessionPath)
														mkdir(obj.sessionPath)
												end
												if ~obj.experimentRunning
														CURRENT_EXPERIMENT_NAME =  obj.stimulusPresentationObj.fileName(1:4);
														obj.updateExperimentName();
														obj.trigger();
												end
										case 'ExperimentStop'
												CURRENT_EXPERIMENT_NAME = obj.currentExperimentName;
												obj.stop();
								end
						end
				end
				function trialStateChangeFcn(obj,src,evnt)
						try
							obj.updateExperimentName
								trialnumber = obj.stimulusPresentationObj.currentTrialNumber;
								if ~isempty(obj.currentDataFile)
										obj.currentDataFile.experimentName = obj.currentExperimentName;
										if ~isempty(obj.currentDataFile.trialNumber)
												% previous data-file -> save it
												obj.saveDataFile;
												notify(obj,'NewTrial')
												% exits after creating new (blank) currentDataFile
										end
										obj.currentDataFile.trialNumber = trialnumber;
										obj.currentDataFile.experimentName = obj.currentExperimentName;
										fprintf('Start of Trial: %i\n',trialnumber);
								end
						catch me
								warning(me.message)
								disp(me.stack(1));
						end
				end
				function frameAcquiredFcn(obj,src,evnt)
						try
								if isempty(obj.currentDataFile)
										% called on first frame
										obj.currentDataFile = BehaviorFile('rootPath',obj.currentDataSetPath);
								end
								obj.framesAcquired = obj.framesAcquired + 1;
								obj.cameraTriggeredFramesAcquired = obj.cameraTriggeredFramesAcquired + 1;
								% Get Info Structure (about 32 bytes=3.5 MBytes/hr)
								info.FrameNumber = obj.framesAcquired; % CameraSystem records framenumber from camera data
								info.CameraTriggeredFrameNumber = obj.cameraTriggeredFramesAcquired;
								info.TrialNumber = obj.stimulusPresentationObj.currentTrialNumber;
								info.StimStatus = obj.stimulusPresentationObj.stimStatus;
								info.StimNumber = obj.stimulusPresentationObj.stimNumber;
								% may need to check frame number?
								data = [];
								if isclosed(obj.currentDataFile)
										if ~issaved(obj.currentDataFile)
												obj.saveDataFile;
												% if file closes somehow, it will save on the next frame and open a new file
												% e.g. if someone access data while it's open, it will close... ?
										end
										obj.currentDataFile = BehaviorFile('rootPath',obj.currentDataSetPath);
								end
								addFrame2File(obj.currentDataFile,data,info);
						catch me
								warning(me.message)
								disp(me.stack(1));
						end
				end
		end
		methods % SET
				function set.experimentSyncObj(obj,bhv)
						if ~isempty(obj.experimentStateListener)
								obj.experimentStateListener.Enabled = false;
						end
						obj.experimentSyncObj = bhv;
						if isa(obj.experimentSyncObj,'StimulusPresentationInterface')
								obj.experimentStateListener = addlistener(obj.experimentSyncObj,...
										'experimentState','PostSet',@(src,evnt)experimentStateChangeFcn(obj,src,evnt));
						else % probably a BehaviorSystem
								obj.experimentStateListener = addlistener(obj.experimentSyncObj,...
										'ExperimentStart',@(src,evnt)experimentStateChangeFcn(obj,src,evnt));
								addlistener(obj.experimentSyncObj,...
										'ExperimentStop',@(src,evnt)experimentStateChangeFcn(obj,src,evnt));
								obj.experimentStateListener.Enabled = true;
						end
				end
				function set.trialSyncObj(obj,bhv)
						obj.trialSyncObj = bhv;						
						if ~isempty(obj.trialStateListener)
								obj.trialStateListener.Enabled = false;
						end
						if isa(obj.experimentSyncObj,'StimulusPresentationInterface')
								obj.trialStateListener = addlistener(obj.trialSyncObj,...
										'currentTrialNumber','PostSet',@(src,evnt)trialStateChangeFcn(obj,src,evnt));
						else % probably a BehaviorSystem
								obj.trialStateListener = addlistener(obj.trialSyncObj,...
										'NewTrial',@(src,evnt)trialStateChangeFcn(obj,src,evnt));
								obj.trialStateListener.Enabled = false;
						end
				end
				function set.frameSyncObj(obj,cam)
						if ~isempty(obj.frameSyncListener)
								obj.frameSyncListener.Enabled = false;
						end
						obj.frameSyncObj = cam;
						% Define Listener
						obj.frameSyncListener = addlistener(obj.frameSyncObj,...
								'FrameAcquired',@(src,evnt)frameAcquiredFcn(obj,src,evnt));
						obj.frameSyncListener.Enabled = false;
				end
		end
		methods % CLEANUP
				function delete(obj)
						obj.delete@SubSystem;
						delete(obj.stimulusPresentationObj)
				end
		end
		
		
		
		
		
		
end









