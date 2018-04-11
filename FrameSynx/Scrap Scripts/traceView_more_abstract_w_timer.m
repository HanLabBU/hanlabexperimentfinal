classdef traceView < hgsetget
		
		
		
		
		
		
		properties
				dataGeneratorObj
				timerObj
				
				% Settings
				frameRate
				updateRate
				winSize
				units
				yCushion
		end
		properties (SetAccess = protected)
				hFig
				hAx
				hLine
				dataSource
		end
		properties(SetAccess = protected, Dependent)
				experimentObj
				data
		end
		
		
		
		
		
		
		
		
		methods
				function obj = traceView(varargin)
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end
						end
						checkProperties(obj)						
						openFigure(obj)
						setTimer(obj)
				end
				
				function checkProperties(obj)
						if isempty(obj.winSize)
								obj.winSize = 30*10;
						end
						if isempty(obj.updateRate)
								obj.updateRate = 5;
						end
						if isempty(obj.units)
								obj.units = 'frames'; % or seconds
						end
						if isempty(obj.yCushion)
								obj.yCushion = 10;
						end
						if isempty(obj.dataGeneratorObj)
								warning('traceView:checkProperties:NoDataControlObject',...
										'traceView not connected to dataControl object');
						else
								obj.dataSource = @obj.experimentObj;
						end
						if isempty(obj.experimentObj)
								warning('traceView:checkProperties:NoExperimentObject',...
										'traceView not connected to Experiment object');
						end
						if isempty(obj.dataSource)
								warning('traceView:checkProperties:NoData',...
										'Data-source is empty');
						end
				end
				
				function openFigure(obj)
						if isempty(obj.hFig)								
								obj.hFig = figure;
						end
						if isempty(obj.hAx)
								obj.hAx = gca;
						end
						plot(obj.hAx,10:.1:11);
						obj.hLine = get(gca,'children');
						set(obj.hFig,...
								'HandleVisibility','callback',...
								'Renderer','painters');
						set(obj.hAx,...
								'XLimMode','manual',...
								'YLimMode','manual',...
								'ZLimMode','manual',...
								'HandleVisibility','callback',...
								'DrawMode','fast')%,...
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
								'EraseMode','xor',...
								'LineWidth',1.5)
				end	
				
				function setTimer(obj)
						obj.timerObj = timer(...
								'Period',1/obj.updateRate,...
								'BusyMode','drop',...
								'ExecutionMode','fixedRate',...
								'TimerFcn',@(src,evnt)updateTrace(obj,src,evnt));						
				end
				
				function updateTrace(obj,~,~)
						if ~isempty(obj.data)
								if length(obj.data)<obj.winSize
										set(obj.hLine,'YData',obj.data,...
												'XData',1:length(obj.data))
										set(obj.hAx,'XLim',[1 10*round(length(obj.data)+10)/10+10],...
												'YLim',[min(obj.data)-obj.yCushion,  max(obj.data)+obj.yCushion])
								else
										try
												set(obj.hLine,'YData',obj.data((end-obj.winSize-1):end),...
														'XData',(length(obj.data)-obj.winSize-1):length(obj.data))
												set(obj.hAx,'XLim',...
														[length(obj.data)-obj.winSize,  length(obj.data)+floor(obj.winSize/10)],...
														'YLim',[min(obj.data)-obj.yCushion max(obj.data)+obj.yCushion])
										catch me
												me.message
												disp(me.message) 								disp(me.stack(1))
										end
								end
								drawnow
								disp('functionran')
						end
				end
		end
		
		methods 				
				function start(obj)
						if ~isempty(obj.dataGeneratorObj)								
								setDataSource(obj)
						end
						start(obj.timerObj)
				end
				
				function stop(obj)
						stop(obj.timerObj)
				end
				
				function setDataSource(obj,varargin)%todo: manage Experiment change
						stop(obj.timerObj)
						if nargin > 1
% 								src = varargin{1};
								%todo: check input types
						else % no input, check dataControl
								if ~isempty(obj.dataGeneratorObj) 
										obj.dataSource = @obj.experimentObj;
								end
						end
				end
				
				function delete(obj)
						try
						delete(obj.timerObj)
						close(obj.hFig)
						catch me
								me.message
						end
				end				
		end
		
		methods % Set/Get Methods				
				function exp = get.experimentObj(obj)
						if ~isempty(obj.dataGeneratorObj)
								exp = obj.dataGeneratorObj.experimentObj;
						end
				end
				
				function tracedata = get.data(obj)
						if ~isempty(obj.dataSource)
								if ~isempty(obj.experimentObj)
										exp = feval(obj.dataSource);
										tracedata = exp.rawTrace;
								else
										tracedata = [];
								end
						else
								tracedata = feval(obj.dataSource);
						end
				end
		end
		
		
		
		
		
		
end














