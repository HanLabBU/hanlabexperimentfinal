function simpleStart()
% Create SubSystems
bhvsystem = BehaviorSystem;
camsystem = CameraSystem;
% Set Session Path (e.g. Z:\YODA\YODA_2010_06_24)
bhvsystem.sessionPath = uigetdir(pwd,'Create or Locate a Session Path');
% Connect SubSystem Objects to Enable Synchronization
camsystem.behaviorSystemObj = bhvsystem;
bhvsystem.cameraObj = camsystem.cameraObj;
camsystem.sessionPath = camsystem.behaviorSystemObj.sessionPath;
% Start BehaviorSystem (waits for ExperimentStart from BehavCtrl)
bhvsystem.start
assignin('base','camsystem',camsystem);
assignin('base','bhvsystem',bhvsystem);

