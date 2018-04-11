% Clean Up any Previous Junk
clear all
close all
instrreset
imaqreset

% Create Camera and Behavior Systems
% % % dcamsys = CameraSystem('cameraClass','DalsaCamera');
wcamsys = CameraSystem('cameraClass','WebCamera');
bhvsys = BehaviorSystem;

% Set any Properties for each System
wcamsys.externalFrameSyncPeriod = 4;

% Create a Synchronizer and Register Each System
syncer = SystemSynchronizer('gui',0);
% % % syncer.register(dcamsys,'frame')
syncer.register(bhvsys,'experiment','trial')
syncer.register(wcamsys, 'frame')

% Synchronize All Registered Systems
syncer.synchronize()

% Start (make all systems ready for sigal from BehavCtrl
start(wcamsys)
% % % start(dcamsys)
start(bhvsys)