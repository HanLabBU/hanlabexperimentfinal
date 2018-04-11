setprocesspriority

% Start GUI
obj = ExperimentControlGUI;

% Wait for user to set the root-path/save-path
m = msgbox('Set the save-path in the GUI then press OK to set up the WebCamera');
waitfor(m)

% Set Root Paths
obj.cameraSystem.sessionPath = obj.savePath;
obj.behaviorSystem.sessionPath = obj.savePath;

% Start WebCamera (MonkeyCam)
cam = WebCamera;
cam.frameRate = 7.5;
webcamsys = CameraSystem(...
    'cameraObj',cam,...
    'behaviorSystemObj',obj.behaviorSystem,...
    'sessionPath',obj.behaviorSystem.sessionPath);









% Waitfor a MsgBox?
% webcamsys.behaviorSystemObj = ...
%     obj.behaviorSystem;
% 
% 
% webcamsys.sessionPath = ...
%     webcamsys.behaviorSystemObj.sessionPath;
% webcamsys.cameraObj.setup()
% webcamsys.cameraObj.start()


webcamsys.sessionPath
