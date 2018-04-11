classdef FrameViewer < DataViewer
		% for now, call with the following:
		% obj = FrameViewer('experimentObj',exp2)
		
		properties
				imControl
				ROI
				% 				dataGeneratorObj
				% 				experimentObj
		end
		properties
				hImage
				hRoiFig
		end
		properties (SetObservable)
				currentFrameNumber
				currentTrialNumber
				currentChannel
		end
		properties (SetAccess = protected)
			% 				hFig
			% 				hAx
			% 				newExperimentListener
			% 				newDataListener
		end
		properties (SetAccess = protected, Dependent)
				currentData
				trialSet
				availableTrialNumbers % absolute
				availableFrameNumbers
				currentTrialIndex
				currentFrameIndex
				currentTrialObj
				currentFrameData
		end
		properties (Hidden)
				timeDim = 4;
				tsetBackDoor %backdoor trialSet
				videoBackDoor
				dataBufferSetting = 'on' % vs. 'off'
				frameChangeListener
				trialChangeListener
				climSet
				currentTrialVideo %aliased by currentData
				nChannels
		end
		
		
		
		
		
		methods % Setup
				function obj = FrameViewer(varargin)
						if isempty(strfind(computer,'64')) % not 64-bit
							obj.dataBufferSetting = 'off';
						end
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end						
						elseif nargin == 1
							switch class(varargin{1})
								case 'Experiment'
									obj.experimentObj = varargin{1};
								case {'uint16','double','uint32','uint8'}
									obj.videoBackDoor = varargin{1};
								case 'Trial'
									obj.tsetBackDoor = varargin{1};
							end
						end
						checkProperties(obj)
						openFigure(obj)%pf
						setFigProperties(obj)
						createListeners(obj)%pf
						buildControls(obj)
						if isempty(obj.dataGeneratorObj) && ~isempty(obj.experimentObj)
								updateDataSource(obj,obj.experimentObj);
						end
						set(obj.hFig,'HandleVisibility','callback')
				end
				function checkProperties(obj)
						if isempty(obj.ROI)
								obj.ROI = struct('number',0,'figure',-1);
						end
						if isempty(obj.dataGeneratorObj) ...
										&& isempty(obj.experimentObj) ...
										&& isempty(obj.tsetBackDoor) ...
										&& isempty(obj.currentTrialVideo)
								warning('FrameViewer:checkProperties:NoData',...
										'The FrameViewer has no data accessible. Add data to the object');
						end
				end
 				function setFigProperties(obj)
						set(obj.hFig,...
								'MenuBar','none',...
								'DoubleBuffer','on',...
								'Position',[100 400 600 500],...
								'KeyPressFcn',@(src,evnt)keyPressCallback(obj,src,evnt),...
								'Interruptible','on');
							if ~isempty(obj.dataGeneratorObj)
								set(obj.hFig,...
								'CloseRequestFcn',@(src,evnt)hideDontClose(obj,src,evnt));
							end
						set(obj.hAx,...
								'Parent',obj.hFig,...
								'XLim',[1 256],...
								'YLim',[1 256],...
								'HandleVisibility','callback',...
								'CLim',[1 4095],...
								'position',[0 0 1 1])
						obj.climSet = false;
						obj.hImage = image(...
								'CData',zeros(256, 256),...
								'XData',[1 256],...
								'YData',[1 256],...
								'CDataMapping','scaled',...
								'Parent',obj.hAx);%,...
						axis image off ij
% 								'HandleVisibility','callback');
				end
				function createListeners(obj)
						if ~isempty(obj.dataGeneratorObj)
								obj.newExperimentListener = addlistener(...
										obj.dataGeneratorObj,'NewExperiment',...
										@(src,evnt)updateDataSource(obj,src,evnt));
								obj.newDataListener = addlistener(...
										obj.dataGeneratorObj,'NewTrial',...
										@(src,trialEventData)updateTrialAvailability(obj,src,trialEventData)); % note: may be unnecessary
								obj.newDataListener.Enabled = true;
						else
								warning('FrameViewer:createListeners:NoDataControlObject',...
										'FrameViewer not connected to dataControl object');
						end
						obj.frameChangeListener = addlistener(...
								obj,'currentFrameNumber','PostSet',...
								@(src,evnt)updateDisplay(obj,src,evnt));
						obj.trialChangeListener = addlistener(...
								obj,'currentTrialNumber','PostSet',...
								@(src,evnt)updateCurrentData(obj,src,evnt));
				end
				function buildControls(obj)
					% Buttons
						obj.imControl.button.rescale = uicontrol(...
								'String','Re-Scale','Position',[20 20 60 20],...
								'Style','pushbutton',...
								'Enable','on',...
								'UserData',-1,...
								'Callback',@(src,evnt)rescaleCallback(obj,src,evnt));
						obj.imControl.button.cancel = uicontrol(...
								'String','Cancel',...
								'Position',[90 20 60 20],...
								'Style','pushbutton',...
								'Enable','on',...
								'UserData',-1,...
								'Callback',@(src,evnt)cancelCallback(obj,src,evnt));
						obj.imControl.button.roi = uicontrol(...
								'String','ROI',...
								'Position',[160 20 60 20],...
								'Style','pushbutton',...
								'Enable','on',...
								'UserData',-1,...
								'Callback',@(src,evnt)roiCallback(obj,src,evnt));
						obj.imControl.button.rotate = uicontrol(...
								'String','Rotate',...
								'Position',[230 20 60 20],...
								'Style','pushbutton',...
								'Enable','on',...
								'UserData',-1,...
								'Callback',@(src,evnt)rotateCallback(obj,src,evnt));
							% Frame and Trial Information Panel
							obj.imControl.panel.info = uipanel(...
								'units','pixels',...
								'position',[20 60 140 150]);
							a = selectmoveresize;
							set(obj.imControl.panel.info,...
								'ButtonDownFcn','selectmoveresize');
						obj.imControl.text.frametime = uicontrol(...
								'parent',obj.imControl.panel.info,...
								'String','Time: 0',...
								'Position',[20 65 100 15],...
								'Style','text',...
								'HorizontalAlignment','left');
						obj.imControl.text.framenumber = uicontrol(...
								'parent',obj.imControl.panel.info,...
								'String','Frame: 0 of 0',...
								'Position',[20 85 100 15],...
								'Style','text',...
								'HorizontalAlignment','left');
						obj.imControl.text.trialnumber = uicontrol(...
								'parent',obj.imControl.panel.info,...
								'String','Trial: 0 of 0',...
								'Position',[20 105 100 15],...
								'Style','text',...
								'HorizontalAlignment','left');
						obj.imControl.text.expname = uicontrol(...
								'parent',obj.imControl.panel.info,...
								'String','EXP1',...
								'Position',[20 125 100 15],...
								'Style','text',...
								'HorizontalAlignment','left');
						% Build Channel Switch
						if ~isempty(obj.currentTrialObj)
							if size(obj.currentTrialObj.video,3) > 1 % multichannel
								obj.imControl.pop.channelchooser = uicontrol(...
									'parent',obj.imControl.panel.info,...
									'style','popupmenu',...
									'string',cellstr(unique(obj.currentTrialObj.channelFS)),...
									'position',[20 20 40 15]);
								uicontrol('parent',obj.imControl.panel.info,...
									'style','text',...
									'position',[70 20 40 15],...
									'string','Channel');
							end
						end
				end
		end
		methods (Hidden) % Event Response
				function updateDataSource(obj,src,~) %perhaps should change to make work like trialset backdoor thing
						if isa(src,'DataGenerator')
								obj.experimentObj = src.experimentObj;
						elseif isa(src,'Experiment')
								obj.experimentObj = src;								
						end
						if ~isempty(obj.trialSet)
								obj.currentTrialNumber = obj.availableTrialNumbers(1);
								obj.currentFrameNumber = 1;% obj.currentTrialObj.firstFrame; NOTE: should this be changed to availableFrameNumbers(1)? yes!
						end
				end
				function updateTrialAvailability(obj,~,trialEventData)
						finishedTrial = trialEventData.previousTrial;
						%todo: change text, popups, or listboxes
				end
				function updateDisplay(obj,src,evnt) % response to changed frame
						set(obj.imControl.text.framenumber,...
								'String',sprintf('Frame: %i of %i',...
								obj.currentFrameIndex, length(obj.availableFrameNumbers)));
						if ~isempty(obj.currentTrialObj) % don't update if using videoBackDoor
								set(obj.imControl.text.trialnumber,...
										'String',sprintf('Trial: %i of %i',...
										obj.currentTrialIndex, length(obj.trialSet)));
								set(obj.imControl.text.frametime,...
										'String',sprintf('Time: %f', ...
										obj.currentTrialObj.frameTimes(obj.currentFrameIndex) - ...
										obj.currentTrialObj.frameTimes(1)));
						end
						if ~isempty(obj.currentData)
								set(obj.hImage,'cdata',obj.currentFrameData);
								set(obj.hAx,'XLim',get(obj.hImage,'XData'),'YLim',get(obj.hImage,'YData'))
								axis image off ij
								drawnow
						end
				end
				function updateCurrentData(obj,src,evnt) %response to changed trial
						if strcmp(obj.dataBufferSetting, 'on') ...
										&& ~isempty(obj.currentTrialObj)
								obj.currentTrialVideo = obj.currentTrialObj.video;
						end
						if ~obj.climSet
								set(obj.hAx,'CLim',[min(min(obj.currentFrameData))  max(max(obj.currentFrameData))])
						end
				end
		end
		methods % Activation/Deactivation
				function start(obj)
						obj.newDataListener.Enabled = true;
				end
				function stop(obj)
						obj.newDataListener.Enabled = false;
				end
				function delete(obj)
						delete(obj.newDataListener) %getting error???
						delete(obj.newExperimentListener)
						if ishandle(obj.hFig)
								delete(obj.hFig)
						end
				end
		end
		methods (Access = protected) % UI-Control Callbacks
				function keyPressCallback(obj,src,evnt)
						% Pressing 6/rightarrow and 4/leftarrow increase and decrease the frame-number
						% respectively. Holding shift before pressing any of these keys changes the Trial-number
						% instead. Set methods will make sure the Trial/frame numbers are within bounds. Event
						% listeners will respond to the change and update the currentFrameData.
						if strcmp(evnt.Key,'shift')
								return
						else % only care about shift if it's the modifier of another key
								if isempty(obj.currentFrameNumber)
										obj.currentFrameNumber = 1;
								end
								if isempty(obj.currentTrialNumber)
										obj.currentTrialNumber = 1;
								end
								if length(evnt.Modifier) < 1 % no modifier -> change frame
										switch evnt.Key
												case {'numpad6','rightarrow'}
														obj.currentFrameNumber = obj.currentFrameNumber + 1;% Error here at Trial-change
												case {'numpad4','leftarrow'}
														obj.currentFrameNumber = obj.currentFrameNumber - 1;
												otherwise
														return
										end
								elseif strcmp(evnt.Modifier{1},'shift')
										switch evnt.Key
												case {'numpad6','rightarrow'}
														obj.currentTrialNumber = obj.currentTrialNumber + 1;
												case {'numpad4','leftarrow'}
														obj.currentTrialNumber = obj.currentTrialNumber - 1;
												otherwise
														return
										end
								end
						end
				end
				function rescaleCallback(obj,src,evnt)
						if ~isempty(obj.currentFrameData)
								set(obj.hAx,'CLim',[min(min(obj.currentFrameData))  max(max(obj.currentFrameData))])
						end
				end
				function cancelCallback(obj,src,evnt)
				end
				function roiCallback(obj,src,evnt)
						% TODO: make sure the image is rotated/flipped correct
						obj.ROI.number = obj.ROI.number + 1;
						soundsc(sinc(3:.1:100)),soundsc(sinc(3:.1:100)); % like beep
						temp = roipoly;
						obj.ROI.(sprintf('region%03i',obj.ROI.number)) = temp(:);
						roivid = repmat(temp, ...
								[1 1 size(obj.currentData,3) size(obj.currentData,4)]) ...
								.* double(obj.currentData);
						obj.ROI.(sprintf('trace%03i',obj.ROI.number)) = ...
								squeeze(sum(sum(roivid,1),2)) ./ sum(temp(:));
						obj.hRoiFig(obj.ROI.number) = figure;
						subplot(2,1,1);
						imagesc(temp);
						axis image off ij
						title(sprintf('region%03i',obj.ROI.number));
						subplot(2,1,2);
						plot(obj.ROI.(sprintf('trace%03i',obj.ROI.number))');
						title(sprintf('trace%03i',obj.ROI.number));
						figure(obj.hFig);
				end
				function rotateCallback(obj,src,evnt)
						% 						clip = handles.clip;
						%          set(handles.obj.hImage,'cdata',img(clip+1:end-clip,clip+1:end-clip)');
						% 						colormap(gray(256));
						set(obj.hImage,'cdata',rot90(get(obj.hImage,'cdata')));
						
				end
		end
		methods % Set Methods
				function set.currentTrialNumber(obj,newctnumber)
						if isempty(obj.trialSet)
								obj.currentTrialNumber = 1;
								return
						end
						if isempty(newctnumber)
								newctnumber = 1;
						end
						if newctnumber > obj.currentTrialNumber;
								obj.currentTrialNumber = obj.availableTrialNumbers(...
										find(obj.availableTrialNumbers <= newctnumber,1,'last'));
								if newctnumber <= obj.availableTrialNumbers(end)
										obj.currentFrameNumber = obj.availableFrameNumbers(1);
								else
										obj.currentFrameNumber = obj.availableFrameNumbers(end);
								end
						elseif isempty(obj.currentTrialNumber) ...
										|| newctnumber < obj.currentTrialNumber
								obj.currentTrialNumber = obj.availableTrialNumbers(...
										find(obj.availableTrialNumbers >= newctnumber,1,'first'));
								if newctnumber >= obj.availableTrialNumbers(1)
										obj.currentFrameNumber = obj.availableFrameNumbers(end);%BUG: index exceeds matrix dimensions
								else
										obj.currentFrameNumber = obj.availableFrameNumbers(1);
								end
						end
						% sets currentTrialNumber and currentFrameNumber to proper values
						% doesn't actually load a Trial-object
						if strcmp(obj.dataBufferSetting,'yes')
								%TODO: here is where the
						end
				end
				function set.currentFrameNumber(obj,newcfnumber)
						if isempty(obj.trialSet) ...
										&& isempty(obj.videoBackDoor)
								return
						end
						if isempty(newcfnumber)
								newcfnumber = 1;
						end
						if newcfnumber > obj.currentFrameNumber
								% Check to see if requested frame number is within Trial
								if newcfnumber > obj.availableFrameNumbers(end)
										obj.currentTrialNumber = obj.currentTrialNumber + 1;
								end
								obj.currentFrameNumber = obj.availableFrameNumbers(...
										find(obj.availableFrameNumbers >= newcfnumber,1,'first'));
						elseif isempty(obj.currentFrameNumber) ...
										|| newcfnumber < obj.currentFrameNumber
								if newcfnumber < obj.availableFrameNumbers(1)
										obj.currentTrialNumber = obj.currentTrialNumber - 1;
								end								
								obj.currentFrameNumber = obj.availableFrameNumbers(...
										find(obj.availableFrameNumbers <= newcfnumber, 1, 'last'));
						end
				end
		end
		methods % Get methods
				function cdata = get.currentData(obj)
						cdata = obj.currentTrialVideo;
						if isempty(cdata)
								cdata = obj.videoBackDoor;
						end
				end
				function tset = get.trialSet(obj)
						if ~isempty(obj.experimentObj) && ~isempty(obj.experimentObj.trialSet)
								tset = obj.experimentObj.trialSet;
						else
								tset = obj.tsetBackDoor;
						end
				end
				function atnumbers = get.availableTrialNumbers(obj) % absolute numbers returned
						if  ~isempty(obj.trialSet)
								atnumbers = [obj.trialSet.trialNumber]';
						else
								atnumbers = [];
						end
				end
				function afnumbers = get.availableFrameNumbers(obj)
						if ~isempty(obj.currentTrialObj)
								afnumbers = obj.currentTrialObj.frameNumberFS;
						elseif ~isempty(obj.videoBackDoor)
								afnumbers = 1:size(obj.videoBackDoor,length(size(obj.videoBackDoor)));
						else
								afnumbers = [];
						end
				end
				function ctindex = get.currentTrialIndex(obj)
						if ~isempty(obj.currentTrialNumber)
								ctindex = find(obj.availableTrialNumbers == obj.currentTrialNumber,1,'first');
						else
								ctindex = 1;
						end
						%BUG: matrix dimensions must agree during construction
				end % relative index into trialSet
				function cfindex = get.currentFrameIndex(obj)
						if ~isempty(obj.currentFrameNumber)
								cfindex = obj.currentFrameNumber ...
										- obj.availableFrameNumbers(1) ...
										+ 1;
						else
								cfindex = 1;
						end
				end
				function ctobj = get.currentTrialObj(obj)
						if ~isempty(obj.trialSet) ...
										&& ~isempty(obj.currentTrialIndex) ...
										&& obj.currentTrialIndex > 0
								ctobj = obj.trialSet(obj.currentTrialIndex);
						else
								ctobj = [];
						end
				end
				function imdata = get.currentFrameData(obj)
						if isempty(obj.currentChannel)
								obj.currentChannel = 1;
						end
						if isfield(obj.imControl,'pop')
							obj.currentChannel = get(obj.imControl.pop.channelchooser,'value');
						end
						% do ask if this isempty() -> gives bug at trial change
						if ~isempty(obj.videoBackDoor)
								imdata = obj.currentData(:,:,obj.currentChannel,obj.currentFrameIndex);
								return
						end
						if isempty(obj.availableTrialNumbers)
								imdata = [];
								return
						end
						if ~any(obj.availableTrialNumbers == obj.currentTrialNumber)
								obj.currentTrialNumber = obj.availableTrialNumbers(1);
								warning('FrameViewer:getdata:TrialNotAvailable',...
										['Requested Trial not available, retrieving Trial ',num2str(obj.currentTrialNumber)]);
						end
						switch obj.dataBufferSetting
								case 'on' %video is pre-loaded
										try
										imdata = obj.currentTrialVideo(:,:,obj.currentChannel,obj.currentFrameIndex); %BUG HAPPENS HERE
										catch
												imdata = obj.currentTrialObj.video(:,:,obj.currentChannel,obj.currentFrameIndex);
										end
								case 'off'
										imdata = obj.currentTrialObj.video(:,:,obj.currentChannel,obj.currentFrameIndex);
								otherwise
										imdata = [];
						end
				end
		end

		
		
		
end















