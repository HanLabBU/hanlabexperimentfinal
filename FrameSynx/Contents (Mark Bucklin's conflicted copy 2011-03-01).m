% -----------------------------------------------------------------------
% CameraControl - Folder Contents
% FrameSynx Toolbox
% Mark Bucklin 8/23/2010
% -----------------------------------------------------------------------
%
%
% Abstract Classes.
%   Camera                    - Abstract interface for any camera
%   MatlabCompatibleCamera    - Camera subclass that uses 'videoinput'
%
% Classes Derived from Camera
%   WebCamera                 - Cameras compatible with 'winvideo' format
%   DalsaCamera               - Cameras compatible with 'coreco' format (pcdig)
%
% Classes Used by Dalsa the DalsaCamera Class
%   DalsaCamSerialConnection  - Implements serial communication with 1M30P
%   DalsaCameraDefault        - Derived from the DefaultFile class
%   DalsaCameraGUI            - Window with controls and histogram
%
% Classes Used by All Camera-Derived Classes
%   CameraSystem              - Derived from the SubSystem class
%
%
% See also  FRAMESYNX, DATAACQUISITION, SUBSYSTEM, DATAFILE

%   Copyright 2009-2010 Mark Bucklin

