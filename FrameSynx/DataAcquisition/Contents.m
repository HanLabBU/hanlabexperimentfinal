% DATAACQUISITION
%
% This folder and it's subfolders contain classes that each define one
% related set of functions necessary for the following procedures:
%   
%   1. Camera Control and Image Acquisition
%   2. Illumination Control
%   3. Interface with Behavior Control System (for synchronization)
%   4. Data Synchronization and Storage
%
% Files
%   ExperimentControlGUI - This class creates a GUI that enables basic use
%   of many of the functions available in the FrameSynx toolbox.
%   Unfortunately, use of this GUI is more or less restricted to use with
%   one camera. More flexibility is provided by command-line operations, or
%   through the use of the SystemSynchronizerGUI class.
%
% See Also ARDUINOCONTROL, BEHAVCONTROL, CAMERACONTROL,
% ILLUMINATIONCONTROL, SYSTEMSYNCHRONIZATION 