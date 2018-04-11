% BEHAVCONTROL
%
% The classes in this folder are used to construct an interface between
% behavior-control software and use this interface to relay experiment
% state information to other components of the FrameSynx system. Each class
% represents a different level of abstraction from the foreign software. In
% our case, the software is BehavCtrl, which runs on another computer on
% the network.
%
% Files
%   BehavControlInterface         - Specific class for BehavCtrl (derived)
%   StimulusPresentationInterface - Generic/Abstract class that defines
%   properties representing experiment state
%   BehaviorSystem                - This is a SubSystem class which handles
%   internal synchronization and data storage
%
% See Also SYSTEMSYNCHRONIZATION, SUBSYSTEM, CAMERACONTROL, FRAMESYNX
