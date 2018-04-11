classdef TraceViewer < DataViewer
		
		
		
		
		properties % Settings
				winSize
				units
				yCushion
				traceColor%todo
				traceThickness%todo
		end
		properties (SetAccess = protected)
				hLine
		end
		properties(SetAccess = protected, Dependent)
				currentData
		end
		
		
		
		
		
		
		
		methods % Setup
				function obj = TraceViewer(varargin)
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end
						end
						checkProperties(obj)						
						openFigure(obj)%pf
						setFigProperties(obj)
						createListeners(obj)%pf
				end				
				function checkProperties(obj)
						if isempty(obj.winSize)
								obj.winSize = 30*25;
						end
						if isempty(obj.units)
								obj.units = 'frames'; % or seconds
						end
						if isempty(obj.yCushion)
								obj.yCushion = 10;
						end
						if isempty(obj.dataGeneratorObj)
								warning('TraceViewer:checkProperties:NoDataControlObject',...
										'TraceViewer not connected to dataControl object');
						end
				end				
				function setFigProperties(obj)
						plot(obj.hAx,10:.1:11);%todo:create line object instead
						obj.hLine = get(gca,'children');
						set(obj.hFig,...
								'HandleVisibility','callback',...
								'Renderer','painters',...
								'CloseRequestFcn',@(src,evnt)hideDontClose(obj,src,evnt));
						set(obj.hAx,...
								'XLimMode','manual',...
								'YLimMode','manual',...
								'HandleVisibility','callback',...
								'DrawMode','fast')%,...
% 								'ZLimMode','manual',...
% 								'CameraPositionMode','manual',...
% 								'CameraTargetMode','manual',...
% 								'CameraUpVectorMode','manual',...
% 								'CameraViewAngleMode','manual',...
% 								'CLimMode','manual',...
% 								'DataAspectRatioMode','manual',...
% 								'PlotBoxAspectRatioMode','manual',...
% 								'TickDirMode','manual',...
% 								'XTickMode','manual',...
% 								'YTickMode','manual',...
% 								'ZTickMode','manual',...
% 								'XTickLabelMode','manual',...
% 								'YTickLabelMode','manual',...
% 								'ZTickLabelMode','manual')
						set(obj.hLine,...
								'LineWidth',1,...
								'EraseMode','xor')
				end
				function createListeners(obj)
						obj.newExperimentListener = addlistener(...
								obj.dataGeneratorObj,...
								'NewExperiment',...
								@(src,evnt)updateDataSource(obj,src,evnt));
						obj.newDataListener = addlistener(...
								obj.dataGeneratorObj,...
								'FrameInfoAcquired',...
								@(src,evnt)updateDisplay(obj,src,evnt));
						obj.newDataListener.Enabled = false;
				end
		end
		methods (Hidden) % Event Response
				function updateDataSource(obj,src,~)
						obj.experimentObj = src.experimentObj;
				end
				function updateDisplay(obj,~,~)
						if ~isempty(obj.experimentObj) && ~isempty(obj.currentData)
								if length(obj.currentData)<obj.winSize
										set(obj.hLine,'YData',obj.currentData,...
												'XData',1:length(obj.currentData))
										set(obj.hAx,'XLim',[1 10*round(length(obj.currentData)+10)/10+10],...
												'YLim',[min(obj.currentData)-obj.yCushion,  max(obj.currentData)+obj.yCushion])
								else
										try
												set(obj.hLine,'YData',obj.currentData((end-obj.winSize-1):end),...
														'XData',(length(obj.currentData)-obj.winSize-1):length(obj.currentData))
												set(obj.hAx,'XLim',...
														[length(obj.currentData)-obj.winSize,  length(obj.currentData)+floor(obj.winSize/10)],...
														'YLim',[min(obj.currentData)-obj.yCushion max(obj.currentData)+obj.yCushion])
										catch me
												disp(me.message);
												disp(me.stack(1))
										end
								end
% 																drawnow
								% 								disp('functionran')
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
						try
						close(obj.hFig)
						catch me
								me.message
						end
				end
		end
		methods % Set/Get Methods			
				function tracedata = get.currentData(obj)
						if ~isempty(obj.experimentObj);
								tracedata = obj.experimentObj.rawTrace;
						else
								tracedata = [];
						end
				end
		end
		
		
		
		
		
		
end














