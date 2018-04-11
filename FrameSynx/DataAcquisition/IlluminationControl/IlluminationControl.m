classdef IlluminationControl < hgsetget
		
		
		
		
		
		properties (Transient, Hidden)
				dataGeneratorObj
				cameraObj
				frameInfoListener
				cameraStartListener
				cameraReadyListener
				numInSequence				
		end
		properties
				arduinoObj
				arduinoSerialPort
				operationMode % 'listen', 'sense' or 'trigger'
		end
		properties % Sequenced Illumination Info				
				channelSequence
				channels
		end
		properties (Dependent, SetAccess = protected)
				channelLabels
				sequenceLength
		end
		properties (SetObservable, SetAccess = protected)
				currentChannel
				nDataInBuffer
				nDataAcquired				
		end
		properties (SetAccess = protected, Hidden)
				channelDataArray
				channelDataBuffer
		end
		properties (Dependent, SetAccess = protected)
				channelData %Flipped Left to Right?
				channelRecord
		end
		properties (Transient)
				gui
		end
		
		
		
		

		events
				ChannelChange
		end
		
		
		
		
		methods % Constructor
				function obj = IlluminationControl(varargin)
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end
						end
						obj.numInSequence = 1;
						obj.nDataInBuffer = 0;
						obj.nDataAcquired = 0;
						checkProperties(obj);					
				end
		end
		methods % Setup
				function checkProperties(obj)
						if isempty(obj.channelSequence)
								obj.channelSequence = {'red','red','green','green'}; %colors need to be named with different first letters
						end												
						if isempty(obj.currentChannel)
								obj.currentChannel = obj.channelSequence{obj.numInSequence}(1); %first letter of color
						end
						if isempty(obj.operationMode)
                            modes = {'LED-Sensor','LED-Controller'};
                            opmode = menu('Illumination Mode: ',modes);
                            switch opmode
                                case 1
                                    obj.operationMode = 'listen';
                                case 2
                                    obj.operationMode = 'trigger';
                            end
						end
						if isempty(obj.arduinoSerialPort)
								obj.arduinoSerialPort = getComPort('Illumination-Arduino');
						end
				end
				function setup(obj)
						switch obj.operationMode
								case 'trigger'
										if isempty(obj.arduinoObj)
												obj.arduinoObj = LedControllerInterface(...
														'nLeds',2,...
														'ledLabels',obj.channelLabels);
										end
										setup(obj.arduinoObj)
								case 'listen' 
										if isempty(obj.arduinoObj)
												obj.arduinoObj = LedSensorInterface(...
														'nLeds',2,...
														'ledLabels',obj.channelLabels);
										end
										setup(obj.arduinoObj)
						end
						if ~isempty(obj.cameraObj) 
								% Listen to the camera for when to stop/start arduino
								if isempty(obj.cameraStartListener)
										obj.cameraStartListener = addlistener(obj.cameraObj,...
												'CameraLogging',@(src,evnt)cameraLoggingFcn(obj,src,evnt));
								end
								if isempty(obj.cameraReadyListener)
										obj.cameraReadyListener = addlistener(obj.cameraObj,...
												'CameraReady',@(src,evnt)cameraReadyFcn(obj,src,evnt));
								end
								if isrunning(obj.cameraObj) && ~isempty(obj.arduinoObj)
										start(obj);
								end
						else
								% 							makecontrol()
						end
						if ~isempty(obj.arduinoObj) && isempty(obj.frameInfoListener)
								% 								obj.frameInfoListener = addlistener(obj.arduinoObj,...
								% 										'currentData','PostSet',@(src,evnt)arduinoNewDataFcn(obj,src,evnt));
								obj.frameInfoListener = addlistener(obj.arduinoObj,...
										'DataReceived',@(src,evnt)arduinoNewDataFcn(obj,src,evnt));
						end
						obj.channelDataArray = [];
						obj.channelDataBuffer = repmat(' ',[1000 1]);
				end
				function start(obj)
						if ~isempty(obj.arduinoObj) && isempty(obj.frameInfoListener)
								% 								obj.frameInfoListener = addlistener(obj.arduinoObj,...
								% 										'currentData','PostSet',@(src,evnt)arduinoNewDataFcn(obj,src,evnt));
								obj.frameInfoListener = addlistener(obj.arduinoObj,...
										'DataReceived',@(src,evnt)arduinoNewDataFcn(obj,src,evnt));
						else
								obj.frameInfoListener.Enabled = true;
						end
						if obj.arduinoObj.arduinoSetupConfirmed
								start(obj.arduinoObj)								
						else
								disp('waiting for arduino setup to complete')
								tic
								while toc < 3
										pause(.1);
										if obj.arduinoObj.arduinoSetupConfirmed
												start(obj.arduinoObj)
												return
										end
								end
								disp('setup did not confirm; try again')
						end
				end
				function stop(obj)
						stop(obj.arduinoObj)
						obj.channelDataArray = [];
				end
				function tf = isrunning(obj)
						if ~isempty(obj.arduinoObj)
								tf = isrunning(obj.arduinoObj);
						end
				end
				function tf = islogging(obj)
						if ~isempty(obj.arduinoObj) && isrunning(obj.arduinoObj)
								tf = islogging(obj.cameraObj);
						else
								tf = false;
						end
				end
		end
		methods % Set/Get
				function set.operationMode(obj,opmode)
						if ~isa(opmode,'char')
								opmode = 'listen';
						end
						opmode = lower(opmode);
						switch opmode(1:2)
								case {'tr','ma','ac'} % trigger or manual or active
										obj.operationMode = 'trigger';
								case {'li','au','pa'} % listen or auto or passive
										obj.operationMode = 'listen';
								otherwise % sense or arduino ...
										obj.operationMode = 'listen';
						end
				end
				function set.channelSequence(obj,sequence)
						obj.channelSequence = sequence;
						obj.channels = unique(obj.channelSequence);
				end
				function label = get.channelLabels(obj)
						for n = 1:length(obj.channels)
								wholeword = obj.channels{n};
								label{n} = wholeword(1);
								label = make_unique(label,wholeword,1);
						end
						function uniquelabels = make_unique(sublabel,subword,pos) %recursive subfunction
								try
										if length(unique(sublabel)) < length(sublabel) % repeat letter
												pos = pos+1; % increment through letters in color, to find one that is unique
												sublabel{end} = subword(pos);
												uniquelabels = make_unique(sublabel,subword,pos);
										else
												uniquelabels = sublabel;
										end
								catch
										sublabel{end} = '#';
										uniquelabels = sublabel;
								end
						end
				end
				function len = get.sequenceLength(obj)
						len = length(obj.channelSequence);
				end
				function chanstruct = get.channelData(obj)
						mat = char(obj.channelDataArray);
						for n = 1:length(obj.channels)								
								[~,column] = find(mat==obj.channelLabels{n},1,'first');
								vec =  false(size(mat,1),1);
								vec(mat(:,column)==obj.channelLabels{n}) = true;
								chanstruct.(obj.channels{n}) = vec;
						end
				end
				function chanvec = get.channelRecord(obj)
						chanvec = char(obj.channelDataArray)';
						chanvec = chanvec(:);
						chanvec = chanvec(~isspace(chanvec));
				end
		end
		methods % DataGetting Methods
				function data = getData(obj,varargin)
						if nargin>1
								nframes = min([varargin{1}, obj.nDataInBuffer]);
						else
								nframes = obj.nDataInBuffer;
						end
						if nframes>0
								data = obj.channelDataBuffer(1:nframes);
								obj.channelDataBuffer = cat(1,obj.channelDataBuffer(nframes+1:end),repmat(' ',[nframes 1]));
								obj.nDataAcquired = obj.nDataAcquired + nframes;
								obj.nDataInBuffer = obj.nDataInBuffer - nframes;
						else
								data = ' ';
						end
				end
		end
		methods (Hidden, Access = protected)
				function cameraLoggingFcn(obj,src,evnt)
						% Begin Recording Data
						if ~isempty(obj.arduinoObj) && ~isrunning(obj.arduinoObj)
								start(obj.arduinoObj)
						end
				end
				function cameraReadyFcn(obj,src,evnt)
						% Start Arduino
						if ~isempty(obj.arduinoObj) && ~isrunning(obj.arduinoObj)
								start(obj.arduinoObj);
						end
				end
				function arduinoNewDataFcn(obj,src,evnt)
						try
								data = evnt.serialMsg;
								lightson = double(data) ~= double('*');
								if any(lightson)
										obj.currentChannel = data(lightson);
										if ~isempty(obj.cameraObj) && islogging(obj.cameraObj)
												%Commented out when switching to buffered data
												% 										data(double(data)==double('*')) = ' ';
												% 										obj.channelDataArray{length(obj.channelDataArray)+1,1} = data;
												obj.channelDataBuffer(obj.nDataInBuffer + 1) = obj.currentChannel(1); % changed to only take first value if multiple LEDs are on
												obj.nDataInBuffer = obj.nDataInBuffer+1;
										end
								end
						catch me
								disp(me.message)
						end
				end
		end
		methods % Delete
				function delete(obj)
						if ~isempty(obj.arduinoObj)
										delete(obj.arduinoObj);
						end
				end
		end
		
		
		
		
		
end









function makecontrol()
	%% get start/stop direction from user
% 								dbox = figure(...
% 										'WindowStyle','normal',...
% 										'Name','Arduino Interface',...
% 										'BackingStore' ,'off',...
% 										'ButtonDownFcn','if isempty(allchild(gcbf)), close(gcbf), end',...
% 										'Colormap' , [],...
% 										'DockControls'   ,'off',...
% 										'HandleVisibility' , 'callback',...
% 										'IntegerHandle' , 'off',...
% 										'MenuBar'   , 'none',...
% 										'NumberTitle', 'off',...
% 										'PaperPositionMode' ,'auto',...
% 										'Visible', 'on',...
% 										'position',[get(0,'PointerLocation') 250 100]);
% 								pan = uipanel(dbox);
% 								startbutton = uicontrol(...
% 										'parent',pan,...
% 										'style','pushbutton',...
% 										'string','Start',...
% 										'callback','start(obj.arduinoObj)');
% 								stopbutton = uicontrol(...
% 										'parent',pan,...
% 										'style','pushbutton',...
% 										'string','Stop',...
% 										'callback','stop(obj.arduinoObj)');
% 								h = allchild(pan);
% 								for n=2:length(h) % this little trick is written in the function 'stackup()'
% 										setpixelposition(h(n),getpixelposition(h(n-1))+[0 30 0 0]);
% 								end
end