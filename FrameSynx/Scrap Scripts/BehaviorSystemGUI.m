classdef BehaviorSystemGUI
		
		
		properties
				mainFig
				mainAx
				
		end
		
		
		
		
		methods
				function buildFigure(obj)
						try
								%% Image Axes Panel
								figpos = getpixelposition(obj.mainFig);
								leftpanwidth = 250;
								toppanheight = 150;
								leftpanheight = figpos(4)-60-toppanheight;
								topwidth = figpos(3)-60-leftpanwidth;
								toppan1width = round(3*(topwidth-40)/10);
								toppan2width = round(2*(topwidth-40)/10);
								toppan3width = round(5*(topwidth-40)/10);
								figure(obj.mainFig);
								winsize = min(topwidth,leftpanheight);
								set(obj.mainAx,...
										'units','pixels',...
										'parent',obj.mainFig,...
										'position',[leftpanwidth+40 20 ...
										winsize winsize],...
										'tag','campreview',...
										'visible','on');
								axis image off
								colormap(gray)
								%% Experiment Status Panel
								obj.mainControl.exptStatusPan = uipanel(...
										'parent',obj.mainFig,...
										'units','pixels',...
										'tag','experimentstatuspanel',...
										'title','',...
										'position',[20 leftpanheight+40 leftpanwidth toppanheight]);
								obj.mainControl.exptStatusLbl = uicontrol(...
										'parent',obj.mainControl.exptStatusPan,...
										'style','text',...
										'units','pixels',...
										'fontsize',16,...
										'horizontalalignment','left',...
										'string','Experiment: ',...
										'position',[5 toppanheight-35 leftpanwidth/2-5 30]);
								obj.mainControl.exptStatusTxt = uicontrol(...
										'parent',obj.mainControl.exptStatusPan,...
										'style','text',...
										'units','pixels',...
										'fontsize',16,...
										'horizontalalignment','left',...
										'string','Stopped',...
										'position',[leftpanwidth/2 toppanheight-35 leftpanwidth/2-5 30]);
								obj.mainControl.trialNumLbl = uicontrol(...
										'parent',obj.mainControl.exptStatusPan,...
										'style','text',...
										'units','pixels',...
										'fontsize',16,...
										'horizontalalignment','left',...
										'string','Trial: ',...
										'position',[5  toppanheight-65  leftpanwidth/2-5 30]);
								obj.mainControl.trialNumTxt = uicontrol(...
										'parent',obj.mainControl.exptStatusPan,...
										'style','text',...
										'units','pixels',...
										'fontsize',16,...
										'horizontalalignment','left',...
										'string','0',...
										'position',[leftpanwidth/2  toppanheight-65  leftpanwidth/2-5 30]);
								if ~isempty(obj.cameraObj) && isobject(obj.cameraObj)
										if islogging(obj.cameraObj)
												obj.camStatus = 'Recording';
												txtcolor = obj.default.green;
										elseif isrunning(obj.cameraObj)
												obj.camStatus = 'Ready';
												txtcolor = obj.default.yellow;
										else
												obj.camStatus = 'Stopped';
												txtcolor = obj.default.red;
										end
								else
										obj.camStatus = 'Stopped';
										txtcolor = obj.default.red;
								end
								obj.mainControl.camStatusLbl = uicontrol(...
										'parent',obj.mainControl.exptStatusPan,...
										'style','text',...
										'units','pixels',...
										'fontsize',16,...
										'horizontalalignment','left',...
										'string','Camera: ',...
										'position',[5 toppanheight-95 leftpanwidth/2-5 30]);
								obj.mainControl.camStatusTxt = uicontrol(...
										'parent',obj.mainControl.exptStatusPan,...
										'style','text',...
										'units','pixels',...
										'fontsize',16,...
										'fontweight','bold',...
										'foregroundcolor',txtcolor,...
										'horizontalalignment','left',...
										'string',obj.camStatus,...
										'position',[leftpanwidth/2  toppanheight-95 leftpanwidth/2-5 30]);
								obj.mainControl.runButt = uicontrol(...
										'parent',obj.mainControl.exptStatusPan,...
										'style','togglebutton',...
										'units','pixels',...
										'position',[10 10 80 30],...
										'string','Run',...
										'callback',@(src,evnt)runExperimentControlFcn(obj,src,evnt));
								obj.mainControl.previewButt = uicontrol(...
										'parent',obj.mainControl.exptStatusPan,...
										'style','togglebutton',...
										'units','pixels',...
										'position',[100 10 80 30],...
										'string','Preview On',...
										'value',1,...
										'callback',@(src,evnt)previewOnOffFcn(obj,src,evnt));
								%% Stimuli Status Panel
								obj.mainControl.stimStatusPan = uipanel(obj.mainFig,...
										'units','pixels',...
										'tag','stimstatuspanel',...
										'position',[20 20 leftpanwidth leftpanheight],...
										'title','Stimuli');
								%% Online Processing Panel
								obj.mainControl.onlineProcessOptionsPan= uipanel(obj.mainFig,...
										'units','pixels',...
										'tag','onlineprocessingoptionspanel',...
										'position',[leftpanwidth+40 leftpanheight+40 toppan1width toppanheight],...
										'title','Online Image Processing');
								obj.mainControl.onlineTriggeredAvgChk = uicontrol(...
										'parent',obj.mainControl.onlineProcessOptionsPan,...
										'style','checkbox',...
										'tag','onlinetrigavgcheck',...
										'units','pixels',...
										'position',[10 10 toppan1width-15 20],...
										'value',1,...
										'string','Triggered Average');
								obj.mainControl.onlineChannelSepChk = uicontrol(...
										'parent',obj.mainControl.onlineProcessOptionsPan,...
										'style','checkbox',...
										'tag','onlinechannelseparationcheck',...
										'units','pixels',...
										'position',[10 40 toppan1width-15 20],...
										'value',0,...
										'string','Frame Sequence Separation');
								obj.mainControl.onlineMeanTraceChk = uicontrol(...
										'parent',obj.mainControl.onlineProcessOptionsPan,...
										'style','checkbox',...
										'tag','onlinemeantracecheck',...
										'units','pixels',...
										'position',[10 70 toppan1width-15 20],...
										'value',1,...
										'string','Frame-Mean Intensity Trace');
								obj.mainControl.onlineRoiTraceChk = uicontrol(...
										'parent',obj.mainControl.onlineProcessOptionsPan,...
										'style','checkbox',...
										'tag','onlineroitracecheck',...
										'units','pixels',...
										'position',[10 100 toppan1width-15 20],...
										'value',0,...
										'string','ROI Intensity Trace');
								%% Stim Comparison Panel
								obj.mainControl.stimComparisonBg = uibuttongroup(...
										'parent',obj.mainFig,...
										'units','pix',...
										'pos',[leftpanwidth+60+toppan1width leftpanheight+40 toppan2width toppanheight],...
										'tag','resbuttongroup',...
										'title','Image Comparison');
								obj.mainControl.stimcompradio(1) = uicontrol(...
										'parent',obj.mainControl.stimComparisonBg,...
										'style','rad',...
										'unit','pix',...
										'position',[10 100 toppan2width-15 20],...
										'string','Difference');
								obj.mainControl.stimcompradio(2) = uicontrol(...
										'parent',obj.mainControl.stimComparisonBg,...
										'style','rad',...
										'unit','pix',...
										'position',[10 70 toppan2width-15 20],...
										'string','Ratio');
								obj.mainControl.stimcompradio(3) = uicontrol(...
										'parent',obj.mainControl.stimComparisonBg,...
										'style','rad',...
										'unit','pix',...
										'position',[10 40 toppan2width-15 20],...
										'string','Other');
								obj.mainControl.stimcomparisonBlankChk = uicontrol(...
										'parent',obj.mainControl.stimComparisonBg,...
										'style','checkbox',...
										'tag','dispblanksubtractcheck',...
										'units','pixels',...
										'position',[10 10 toppan2width-15 20],...
										'value',0,...
										'string','Subtract Blank Trials');
								%% Preview Display Panel
								popos = getpixelposition(obj.mainControl.stimComparisonBg);
								dopos = popos(1:2) + [popos(3)+20 0];
								obj.mainControl.displayOptionsPan= uipanel(obj.mainFig,...
										'units','pixels',...
										'tag','displayoptionspanel',...
										'position',[dopos toppan3width toppanheight],...
										'title','Main Display');
								%% Colormap
								popwidth = toppan3width/2-40;
								textwidth = toppan3width/2;
								obj.mainControl.imageColormapPop = uicontrol(...
										'parent',obj.mainControl.displayOptionsPan,...
										'style','popup',...
										'tag','colormappop',...
										'units','pixels',...
										'position',[10 10 popwidth 20],...
										'string',obj.default.colormapList,...
										'callback',@(src,evnt)colormapControlFcn(obj,src,evnt));
								obj.mainControl.imageColormapTxt = uicontrol(...
										'parent',obj.mainControl.displayOptionsPan,...
										'style','text',...
										'tag','colormapoptionstext',...
										'units','pixels',...
										'horizontalalignment','left',...
										'position',[popwidth+10 10 textwidth 20],...
										'string','Colormap');
								obj.mainControl.colormapSaturationChk  = uicontrol(...
										'parent',obj.mainControl.displayOptionsPan,...
										'style','checkbox',...
										'tag','colormapsaturationcheck',...
										'units','pixels',...
										'position',[10 40 toppan3width/2 20],...
										'value',0,...
										'string','Show Saturation in Colormap',...
										'callback',@(src,evnt)colormapControlFcn(obj,src,evnt));
								%% Preview Flip
								obj.mainControl.previewFlipLeftRightButt = uicontrol(...
										'parent',obj.mainControl.displayOptionsPan,...
										'style','pushbutton',...
										'units','pixels',...
										'position',[10 70 60 20],...
										'string','Flip LR',...
										'callback',@(src,evnt)previewFlipFcn(obj,src,evnt));
								obj.mainControl.previewFlipUpDownButt = uicontrol(...
										'parent',obj.mainControl.displayOptionsPan,...
										'style','pushbutton',...
										'units','pixels',...
										'position',[80 70 60 20],...
										'string','Flip UD',...
										'callback',@(src,evnt)previewFlipFcn(obj,src,evnt));
								%% Movie Sequence Style
								% 								obj.mainControl.movieSequenceOptionPop= uicontrol(...
								% 										'parent',obj.mainControl.displayOptionsPan,...
								% 										'style','popup',...
								% 										'tag','moviesequenceoptionpop',...
								% 										'units','pixels',...
								% 										'position',[10 70 popwidth 20],...
								% 										'string',obj.default.moveSequenceOptions);
								% 								obj.mainControl.movieSequenceOptionTxt = uicontrol(...
								% 										'parent',obj.mainControl.displayOptionsPan,...
								% 										'style','text',...
								% 										'tag','moviesequenceoptiontext',...
								% 										'units','pixels',...
								% 										'horizontalalignment','left',...
								% 										'position',[popwidth+10 70 textwidth 20],...
								% 										'string','Movie-Sequence Options');
								%% Menu
								buildMenu(obj)
						catch me
								warning(me.message)
								disp(me.stack(1))
						end
				end
				
				function buildBehaviorPanel(obj)
						%% Initialize Figure
						obj.bhvControlFig = figure;
						set(obj.bhvControlFig,...
								'units','pixels',...
								'tag','bhvconfigpanel',...
								'menubar','none',...
								'name','BehavControl Configuration',...
								'numbertitle','off',...
								'resize','off',...
								'position',obj.pos.bhvpanel);
						%% BehavControl Settings
						obj.bhvControl.behavPan = uipanel(...
								'parent',obj.bhvControlFig,...
								'units','pixels',...
								'tag','behavpanel',...
								'position',[10 obj.pos.bhvpanel(4)-70 220 50],...
								'title','BehavControl Settings');
						obj.bhvControl.behavCompnameTxt = uicontrol(obj.bhvControl.behavPan,...
								'style','edit',...
								'tag','behavcompedit',...
								'units','pixels',...
								'horizontalalignment','left',...
								'position',[10 10 130 20],...
								'string',obj.default.behavControlComputerName);
						obj.behavControlComputerName = obj.default.behavControlComputerName;
						obj.bhvControl.listenForBehavButt = uicontrol(obj.bhvControl.behavPan,...
								'style','toggle',...
								'tag','listenforbehavbutt',...
								'units','pixels',...
								'position',[150 10 60 20],...
								'string','Connect');
						set([obj.bhvControl.behavCompnameTxt, obj.bhvControl.listenForBehavButt],...
								'callback',@(src,evnt)behavControlControlFcn(obj,src,evnt));
						%% Log Box
						obj.bhvControl.logBox = uicontrol(...
								'parent',obj.bhvControlFig,...
								'units','pixels',...
								'tag','behavlog',...
								'position',[10 10 obj.pos.bhvpanel(3)-20 obj.pos.bhvpanel(4)-90],...
								'style','edit',...
								'max',100,...
								'enable','inactive',...
								'horizontalalignment','left',...
								'string',obj.behavControlMsgLog);
						connectBhv(obj)
				end
				
				
				
				function setFigureAccess(obj)
						set([obj.mainFig; obj.componentControlFigs],...
								'HandleVisibility','callback');
						set(obj.componentControlFigs,...
								'visible','off',...
								'CloseRequestFcn',@(src,evnt)hideDontClose(obj,src,evnt));
				end
		end
		
		
end





