classdef BehavControlInterface < StimulusPresentationInterface
		
		
		
		
		properties (Access = protected, Hidden)
				dataGeneratorObj
		end		
		properties
				BhvControlComputerName
				stimIP
				remotePort
				localPort
				showLog
				savePath
		end		
		properties (SetAccess = protected, AbortSet, SetObservable, Hidden)
				stimPhase
				unkownMsg
				udpListener
				logBox
				lastMsgHatTime
		end		
		properties (Hidden)
				default
		end		
		properties (Dependent, SetAccess = private)
				% properties that refer to central data in dataMaker object
				saveRoot
		end
		
		
		
		events
				BehavControlMsg
				% 					ExperimentStart
				% 					ExperimentStop
				% 					NewTrial
				% 					NewStimulus
		end
		
		
		
		
		methods % Constructor/Destructor
				function obj = BehavControlInterface(varargin)
						try
								% Argument Checking and Defaults
								if nargin > 1
										for k = 1:2:length(varargin)
												obj.(varargin{k}) = varargin{k+1};
										end
								end
								obj.codeTable = StimulusPresentationInterface.defineCodeTable();
								checkProperties(obj)
								% Log File and Display Management
								createLogFile(obj)
								obj.udpListener = createUDP(obj);
								fopen(obj.udpListener);
						catch me
								beep
								disp(me.stack(1))
								warning(me.message)
						end
				end
				function delete(obj)
						try
                            if isvalid(obj)
								closemsg = ['BehavControlInterface deleted at: '....
										datestr(now),'\r\n'];
								if ~isempty(obj.logFile)
										fprintf(obj.logFile,closemsg);
										[templogfilestring,~,~,~] = fopen(obj.logFile);
										fclose(obj.logFile);
										movefile(templogfilestring,fullfile(obj.saveRoot,obj.logFileName));
								end
								openfiles = fopen('all');
								if ~isempty(openfiles)
										for n = 1:length(openfiles)
												fclose(openfiles(n));
										end
								end
								if exist(templogfilestring,'file')
										delete(templogfilestring);
								end
								if isvalid(obj.udpListener)
										fclose(obj.udpListener);
										delete(obj.udpListener);
								end
								if ~isempty(obj.logBox) && ishandle(obj.logBox.fig)
										close(obj.logBox.fig)
                                end
                            end
						catch me
								disp(me.stack(1))
								warning(me.message)
								beep
						end
				end
				function checkProperties(obj)
						obj.default = BehavControlInterfaceDefault;
						props = properties(obj);
						for n = 1:length(props)
								prop = props{n};
								if isempty(obj.(prop)) && any(strcmp(properties(obj.default),prop))
										obj.(prop) = obj.default.(prop);
								end
						end
						if isempty(obj.logFileName)
								obj.logFileName = ['Bhv_UDP_Log_',date,'.txt'];
						end
% 						if isempty(obj.localPort)
% 								obj.localPort = obj.default.localPort;
% 						end
% 						if isempty(obj.remotePort)
% 								obj.remotePort = obj.default.remotePort;
% 						end
% 						if isempty(obj.BhvControlComputerName)
% 								tmp = inputdlg(...
% 										'Enter the name of the computer running BehavControl',...
% 										'BehavControl Computer Name',1,...
% 										{obj.default.BhvControlComputerName});
% 								obj.BhvControlComputerName = tmp{1};
% 						end
						if isempty(obj.showLog)
								choice = questdlg('Display BehavControl Log?');
								if strcmpi(choice,'yes')
										obj.showLog = 'yes';
								else
										obj.showLog = 'no';
								end
						end
% 						if isdir(obj.default.savePath)
% 								obj.savePath = obj.default.savePath;
% 								disp(['BehavControl log file will be saved to: ',obj.savePath]);
% 						else
% 								obj.savePath = uigetdir(pwd,...
% 										'Choose the directory where BehavControl communication logs will be saved');
% 						end
				end
		end
		methods (Access=protected) % Configuration methods for code readability
				function udpListener = createUDP(obj)
						[~,obj.stimIP] = resolvehost(obj.BhvControlComputerName);
						objects = instrfind;
						objtypes = get(objects,'type');
						udpObjects = objects(strcmp('udp',objtypes));
						if ~isempty(udpObjects)
								udpObjects = udpObjects(strcmp(obj.stimIP,udpObjects.RemoteHost));
								if ~isempty(udpObjects)
										delete(udpObjects)
								end
						end
						udpListener = udp(obj.stimIP,obj.remotePort,'localport',obj.localPort);
						set(udpListener,...
								'DatagramReceivedFcn',@(src,event)messageReceivedFcn(obj,src,event),...
								'Name',[obj.BhvControlComputerName,' UDP Listener'],...
								'DatagramTerminateMode','off',...
								'ReadAsyncMode','continuous',...
								'InputBufferSize',2^12,...
								'ByteOrder','bigEndian');
				end
				function createLogFile(obj)
						logfileexist = exist(fullfile(obj.saveRoot,obj.logFileName),'file');
						if  logfileexist == 2 % File Exists
								copyfile(fullfile(obj.saveRoot,obj.logFileName),fullfile(obj.saveRoot,'templog.txt'))
						elseif ~isdir(obj.saveRoot) % Directory Does Not Exist
								[~,~,~] = mkdir(obj.saveRoot);
						end
						obj.logFile = fopen(fullfile(obj.saveRoot, 'templog.txt'),'a');
						openmsg = ['BehavControlInterface opened at: ',datestr(now)];
						fprintf(obj.logFile,[openmsg,'\r\n']);
						if strcmpi(obj.showLog,'yes')
								createLogBox(obj,openmsg)
						end
				end
				function createLogBox(obj,msg)
						if isempty(msg)
								msg = datestr(now);
						end
						scz = get(0,'screensize');
						obj.logBox.fig = figure('position',[25 100 350 scz(4)-150]);
						obj.logBox.txtBox = uicontrol( ...
								'parent',obj.logBox.fig,...
								'units','normalized',...
								'position',[0 0 1 1],...
								'Style','edit',... %changed from text
								'HorizontalAlignment','left',...
								'DeleteFcn',{@logDisplayClosed,obj},...
								'tag','behavlog',...
								'max',100,...
								'enable','inactive');
% 								'position',[1 25 320 scz(4)-200],...

						obj.logBox.text = {msg};
						set(obj.logBox.txtBox,'string',obj.logBox.text);
						obj.logBox.n = 1;
				end
		end
		methods (Access = protected) % UDP Message Processing Function
				function messageReceivedFcn(obj,~,~)
						if strcmp(obj.udpListener.DatagramAddress,obj.stimIP)
								obj.lastMsgRcvTime = clock;
								try
								obj.lastMsgHatTime = hat;
								catch me
										warning(me.message)
								end
								msgType = fread(obj.udpListener,2);
								msgType = char(msgType');
								switch msgType
										case 'SY'
												readSync(obj);
										case 'FN'
												readFilename(obj);
								end
						else % message did not come from correct computer, ignore it
								flushinput(obj.udpListener)
						end
				end
				function readSync(obj)
						% Read Sync-Message and Determine Which State has Changed
						msg = fread(obj.udpListener,6);
						channel = msg(1);
						code = msg(5)*65536 + msg(4)*256 + msg(3);
						switch channel
								case 0 %StimState: ON, SHIFT, OFF, or STIM#
										readStimState(obj)
								case 1 %ExperimentState:  PAUSE, UNPAUSE, FINISHED, or START
										readExpState(obj)
								case 2 %Trial Number
										readTrialNum(obj)
						end
						writeLogMsg(obj)
						% State-Change Subfunctions
						function readStimState(obj)
								if code>100000 % traditional code for stim on, shift, off, or number
										pcode = code-100000;
										if pcode<4 % Not a stim Number
												msg = obj.codeTable{1,pcode}; % {on, shift, off}
										else
												obj.stimNumber = pcode-3;
												msg = [obj.codeTable{1,4}, num2str(obj.stimNumber)];
										end
								obj.stimState = msg;
								else % rapidfire stim-phase measurement
										obj.stimPhase = code;
										msg = ['stim-phase: ', num2str(obj.stimPhase)];
								end
								obj.lastMsgRcvd = msg;
								switch obj.stimState
										case 'stim on'
												obj.stimStatus = 1;
										case 'stim shift'
												obj.stimStatus = obj.stimStatus + 1;
										case 'stim off'
												obj.stimStatus = 0;
												obj.stimNumber = NaN;
										otherwise %stim number
												obj.stimStatus = 1;
								end
						end
						function readExpState(obj)
								pcode = code-2000;
								obj.experimentState = obj.codeTable{2,pcode};
								obj.lastMsgRcvd = obj.codeTable{2,pcode};
								switch obj.experimentState
										case 'start exp'
												notify(obj,'ExperimentStart')
										case 'finished'
												notify(obj,'ExperimentStart')
								end
						end
						function readTrialNum(obj)
								obj.stimState = obj.codeTable{1,3}; % reset stim-state to 'stim: off' in case packet is lost
								if code ~= obj.currentTrialNumber
										notify(obj,'NewTrial')
								end
								obj.currentTrialNumber = code;
								obj.lastMsgRcvd = ['Trial ',num2str(code)];
								obj.stimNumber = NaN;								
						end
						function writeLogMsg(obj)
								logmsg = {['ch',num2str(channel),' - '],...
										[num2str(obj.lastMsgRcvTime(4)),':',...
										num2str(obj.lastMsgRcvTime(5)),':',...
										num2str(obj.lastMsgRcvTime(6)),' - '],...
										[obj.lastMsgRcvd,'  '],...
										['(',num2str(code),')'],};
								fprintf(obj.logFile,[logmsg{1} logmsg{2} logmsg{3} logmsg{4}, '\r\n']);
								logmsg = {[logmsg{1},logmsg{2},logmsg{3},logmsg{4}]};
								notify(obj,'BehavControlMsg',behavMsg(logmsg));
								try
										if strcmpi(obj.showLog,'yes') && ishandle(obj.logBox.txtBox)
% 												ex = get(obj.logBox.txtBox,'extent');
% 												pos = get(obj.logBox.txtBox,'position');
% 												if ex(4) >= pos(4)
% 														obj.logBox.n = obj.logBox.n + 1;
% 												end
												obj.logBox.text = [logmsg ; obj.logBox.text];
												set(obj.logBox.txtBox,'string',obj.logBox.text);
										end
								catch me
										warning(me.message)
								end
						end
						
				end
				function readFilename(obj)
						fnLength = fread(obj.udpListener,2);
						filename = fread(obj.udpListener,fnLength(1));
						filename = char(filename');
						filename = filename(1:end-6);
						obj.fileName = filename;
						if strcmpi(obj.showLog,'yes') && ishandle(obj.logBox.txtBox)
								try
										topText = obj.logBox.text(obj.logBox.n:end);
										obj.logBox.text = [topText ; filename];
										set(obj.logBox.txtBox,'string',obj.logBox.text);
								catch me
										warning(me.message)
								end
						end
						fnmessage = ['Experiment Name: ',obj.fileName];
						fprintf(obj.logFile, [fnmessage,'\r\n']);
						notify(obj,'BehavControlMsg',behavMsg(fnmessage));
				end
		end
		methods % Get Methods
				function sroot = get.saveRoot(obj)
						if isempty(obj.dataGeneratorObj)
								if ~isempty(obj.savePath)
										sroot = obj.savePath;
								else
										sroot = pwd;
								end
						else
								sroot = obj.dataGeneratorObj.savePath;
						end
						if ~isdir(sroot)
								succ = mkdir(sroot);
								if ~succ
										sroot = pwd;
										warning('BehavControlInterface:saveRoot:reset',...
												'BehavControl log directory changed from %s  to  %s',obj.savePath,sroot);
										obj.savePath = sroot;										
								end
						end
				end
		end
		
		
		
		
		
		
		
end








% Utility Functions
function logDisplayClosed(~,~,obj)
if ishandle(obj)
		obj.showLog = 'no';
end
end

% Rough Translation of BehavControl UDP Messages
% STIM STATE CHANGE
% SY0100001 stim on
% SY0100002 stim shift
% SY0100003 stim off
% SY0100004 stim 1
% SY0100005 stim 2
% SY0100006 stim 3 ... etc
%
% EXPERIMENT STATE CHANGE
% SY12001   pause
% SY12002   unpause
% SY12003   finished
% SY12004   start
%
% TRIAL NUMBER CHANGE
% SY2369    start Trial 369
% SY2370    start Trial 370 ... etc
%
% FILENAME
% FNTWK1    filename is TWK1







