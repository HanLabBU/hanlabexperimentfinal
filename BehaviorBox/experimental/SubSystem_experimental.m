classdef SubSystem < hgsetget
  % ------------------------------------------------------------------------------
  % SubSystem
  % FrameSynx toolbox
  % 2/8/2010
  % Mark Bucklin
  % ------------------------------------------------------------------------------
  %
  % The SubSystem class is an abstract class, meant to provide a standard
  % set of methods for data acquisition and saving. Any object of a class
  % that is derived from the SubSystem class (e.g. CameraSystem, or
  % BehaviorSystem) can be synchronized with any other SubSystem-derived
  % objects. Synchronization is accomplished through the use of three
  % event-types: ExperimentSync, TrialSync, and FrameSync. The object that
  % will broadcast each event - the "master-clock" if you will - is
  % determined by assigning that object to the respective field in another
  % object. For example, to synchronize an object of the BehaviorSystem
  % class with an object of the CameraSystem class, one would assign the
  % CameraSystem object to the 'frameSyncObj' property of the
  % BehaviorSystem object:
  %
  % EXAMPLE:
  % >> bhvsys = BehaviorSystem;
  % >> camsys = CameraSystem;
  % >> bhvsys.frameSyncObj = camsys;
  % >> camsys.experimentSyncObj = bhvsys;
  % >> camsys.trialSyncObj = bhvsys;
  %
  % The three event-types are used to synchronize the start and stop of the
  % acquisition (ExperimentSync), the saving of each DataFile (TrialSync),
  % and the frequency of data acquisition (FrameSync).
  %
  % SubSystem-derived objects can be created and synchronized manually, or
  % by using the SystemSynchronizer class, which automates the process and
  % ensures that there is one master-clock for each event type, and that
  % every object of the SubSystem class that has been "registered" with the
  % SystemSynchronizer is synchronized with the correct object. It also
  % handles synchronization of filepaths.
  %
  %
  % SubSystem Properties:
  %     currentDataFile - An object of a type derived from the DataFile
  %     class (VideoFile or BehaviorFile) that is currently open and being
  %     filled with data.
  %
  %     currentDataFileSet - The set of most recently made DataFile
  %     objects, which will be saved to a Mat file and forgotten when
  %     'saveDataSet' is called.
  %
  %     savedDataFiles - Previously held all DataFile objects which had
  %     been saved to a Mat file, however this property is not always used
  %     anymore.
  %
  %     systemName - A name used to differentiate multiple systems of the
  %     same type, e.g. multiple CameraSystems.
  %
  %     currentExperimentName - The name determined from the
  %     ExperimentSyncObj (normally acquired over UDP from BehavCtrl).
  %     Defaults to EXPX.
  %
  %     currentDataSetPath - Determined automatically from the savePath
  %     property and the currentExperimentName.
  %
  %     saveSetting - A switch to control how data is saved as it is
  %     acquired.
  %
  %     autoSaveFrequency - The number of trials (or calls to
  %     'saveDataFile') before the currentDataFileSet is saved to a Mat
  %     file and cleared from memory.
  %
  %     savePath - Should be assigned if not handled with GUI. Defaults to
  %     Z:\TEST\TEST_[date]\  .
  %
  %     frameDataCallbackFcn - A callback function can be assigned to this
  %     property to perform some operation on the data acquired in each
  %     frame. See details in the CameraSystem class documentation.
  %
  % SubSystem Methods:
  %   experimentStateChangeFcn - (abstract) trigger or stop acquisition
  %   trialStateChangeFcn - (abstract) save a DataFile object
  %   frameAcquiredFcn - (abstract) record data and write to currentDataFile
  %   start - (abstract) prepare system for acquisition
  %   stop - (abstract) stop acquisition
  %   saveDataFile - save and close currentDataFile
  %   saveDataSet - save currentDataFileSet in Mat file
  %   clearDataSet - clear currentDataFileSet
  %   updateExperimentName - check experimentSyncObj for experiment name
  %   isready - true if system has been started
  %   isvalid - true if system has NOT been deleted
  %
  % See also CAMERASYSTEM, BEHAVIORSYSTEM, DATAFILE, SYSTEMSYNCHRONIZER,
  % DATAACQUISITION, FRAMESYNX
  %
  
  
  
  
  
  
  properties (Abstract)
    experimentSyncObj %Synchronizes the start and stop of data acquisition by calling the experimentStateChangeFcn
    trialSyncObj %Synchronizes DataFile saves so that chunks of data can be syncronized across systems
    frameSyncObj %Synchronizes the acquisition of data. The object assigned to this property essentially sets the 'frame-rate'.
  end
  properties
    currentDataFile %An object of a type derived from the DataFile class (VideoFile or BehaviorFile) that is currently open and being filled with data
    currentDataFileSet %The set of most recently made DataFile objects, which will be saved to a Mat file and forgotten when 'saveDataSet' is called.
    savedDataFiles %Previously held all DataFile objects which had been saved to a Mat file, however this property is not always used anymore.
    systemName %A name used to differentiate multiple systems of the same type, e.g. multiple CameraSystems
    currentExperimentName %The name determined from the ExperimentSyncObj (normally acquired over UDP from BehavCtrl). Defaults to EXPX.
    currentDataSetPath %Determined automatically from the savePath property and the currentExperimentName
    saveSetting %A switch to control how data is saved as it is acquired.
    autoSaveFrequency %The number of trials (or calls to 'saveDataFile') before the currentDataFileSet is saved to a Mat file and cleared from memory.
    savePath %Should be assigned if not handled with GUI. Defaults to Z:\TEST\TEST_[date]\
    frameDataCallbackFcn %A callback function can be assigned to this property to perform some operation on the data acquired in each frame. See details in the CameraSystem class documentation.
  end
  properties (Hidden)
    frameSyncListener
    experimentStateListener
    trialStateListener
    framesAcquired
    nDataFiles
    sessionPath
    nSavedDataSets
    experimentRunning
    default
    ready
  end
  properties (Transient, Hidden)
    gui
  end
  
  
  
  
  
  
  
  methods (Abstract)
    createSystemComponents(obj)
    start(obj)
    stop(obj)
    experimentStateChangeFcn(obj,src,evnt)
    trialStateChangeFcn(obj,src,evnt)
    frameAcquiredFcn(obj,src,evnt)
  end
  methods % INITIALIZATION
    function defineDefaults(obj)
      % standard function for defining defaults
      persistent sysnum
      if isempty(sysnum)
        sysnum = 1;
      else
        sysnum = sysnum+1;
      end
      obj.default.sessionPath =  fullfile(['Z:\TEST\',...
        'TEST_',datestr(date,'yyyy_mm_dd')]);
      obj.default.systemName =  [class(obj),'-',num2str(sysnum)];
      obj.default.saveSetting = 'memory';
      obj.default.autoSaveFrequency = 5;
      obj.default.currentDataSetPath = fullfile(obj.default.sessionPath,'ORPHANAGE');
    end
    function checkProperties(obj)
      props = properties(obj);
      for n = 1:length(props)
        prop = props{n};
        if isempty(obj.(prop)) && isfield(obj.default,prop)
          obj.(prop) = obj.default.(prop);
        end
      end
      obj.nDataFiles = 0;
      obj.nSavedDataSets = 0;
    end
    function b = isready(obj)
      % USAGE:
      % >> isready(obj);
      % or
      % >> obj.isready;
      if isempty(obj.ready)
        b = false;
      else
        b = obj.ready;
      end
    end
  end
  methods % DATA MANAGEMENT
    function updateExperimentName(obj)
      global CURRENT_EXPERIMENT_NAME
      if ~isempty(CURRENT_EXPERIMENT_NAME)
        obj.currentExperimentName = CURRENT_EXPERIMENT_NAME;
      else
        obj.currentExperimentName = 'EXPX';
      end
    end
    function varargout = saveDataFile(obj)
      % called at end of every trial
      try
        if obj.nDataFiles >= obj.autoSaveFrequency
          obj.saveDataSet();
          nfile = 1;
        else
          nfile = obj.nDataFiles + 1;
        end
        obj.updateExperimentName();
        if ~isempty(obj.currentDataFile)
          fulldatafile = obj.currentDataFile;
          datafileclass = class(fulldatafile);
          obj.currentDataSetPath =  fullfile(obj.sessionPath, obj.currentExperimentName);
          % create new DataFile (i.e. VideoFile or BehaviorFile)
          instantiation_command = sprintf('%s(''rootPath'',''%s'')',...
            datafileclass, obj.currentDataSetPath);
          obj.currentDataFile = eval(instantiation_command);
          fulldatafile.nextDataFile = obj.currentDataFile;
          obj.currentDataFile.previousDataFile = fulldatafile;
          % Close Previous-Previous Data-File
          if ~isempty(fulldatafile.previousDataFile) && isopen(fulldatafile.previousDataFile)
            closeFile(fulldatafile.previousDataFile);
          end
          fulldatafile.previousDataFile = []; % Added to prevent slowdowns from increasing memory
        else
          fulldatafile = DataFile.empty(0,1);
        end
        obj.currentDataFileSet(nfile) = fulldatafile;
        obj.nDataFiles = nfile;
        if nargout>0
          varargout{1} = fulldatafile;
        end
      catch me
        warning(me.message)
        disp(me.stack(1));
      end
    end
    function varargout = saveDataSet(obj)
      % called at end of each experiment or after some number of trials (autoSaveFrequency)
      datafileclass = class(obj.currentDataFileSet);
      if ~isempty(obj.currentDataFileSet)
        partname = lower(datafileclass);
        partname = partname(1:3);
        tmp.(sprintf('%sfiles',partname)) = obj.currentDataFileSet;
        if isempty(obj.currentExperimentName)
          obj.currentExperimentName = 'EXPX';
        end
        expt_name = obj.currentExperimentName;
        if isempty(obj.currentDataSetPath)
          obj.currentDataSetPath = obj.sessionPath; % obj.currentDataFileSet(1).rootPath; % or session path?
          % 								expt_savepath = [expt_savepath,filesep,expt_name];
        else
        end
        if ~isdir(obj.currentDataSetPath)
          mkdir(obj.currentDataSetPath);
        end
        setnumber = obj.nSavedDataSets + 1;
        fname = sprintf('%s_%s_SET%i',expt_name,...
          obj.systemName,...
          setnumber);
        fname = [fullfile(obj.currentDataSetPath,fname),'.mat'];
        fname = fname(isstrprop(fname,'graphic'));
        tic%<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        % Check for File Repeats and Change Name so as not to Overwrite
        repeatfile = 96;
        while exist(fname,'file')
          repeatfile = repeatfile+1; %(97=a, 98=b, etc.)
          fname = [fname(1:end-4),char(repeatfile),'.mat'];
        end
        % Save Data-File Set and Forget (to Save Memory)
        save(fname,'-struct', 'tmp', '-v6' )
        fprintf('Data-Files Saved: %s\n',fname)
        fprintf('Save Time: %0.3f seconds\n',toc);%<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        if nargout > 1
          varargout{1} = fname;
        end
        obj.currentDataFileSet = eval(sprintf('%s.empty(0,%i)',datafileclass,min(100,obj.autoSaveFrequency)));
        obj.nSavedDataSets = setnumber;
        obj.savedDataFiles{setnumber} = fname;
      end
    end
    function clearDataSet(obj)
      if ~isempty(obj.currentDataFileSet)
        obj.saveDataSet()
      end
      obj.nDataFiles = 0;
      obj.nSavedDataSets = 0;
      DataSet_FileList = obj.savedDataFiles;
      if ~isempty(DataSet_FileList)
        fname = fullfile(obj.currentDataSetPath,...
          sprintf('FileList_%s_%s',obj.currentExperimentName,...
          obj.systemName));
        fname = [fname,'.mat'];
        save(fname,'DataSet_FileList','-v6');
        fprintf('Saving Data-Set File-List: %s\n',fname);
      end
      obj.savedDataFiles = cell.empty(0,1);
    end
  end
  methods % SET
    function set.savePath(obj,spath)
      % for temporary backwards compatibility
      obj.sessionPath = spath;
      obj.savePath = spath;
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













