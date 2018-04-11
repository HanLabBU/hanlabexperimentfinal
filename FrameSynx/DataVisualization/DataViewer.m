classdef DataViewer < hgsetget
		
		
		
		
		properties
				dataGeneratorObj
				experimentObj
		end
		properties (SetAccess = protected)
				hFig
				hAx
				newExperimentListener
				newDataListener
		end
		properties (SetAccess = protected, Dependent, Abstract)
				currentData
		end
		
		
		
		
		methods (Abstract)
				checkProperties(obj)
				setFigProperties(obj)
				updateDataSource(obj)
				updateDisplay(obj)
				start(obj)
				stop(obj)
		end
		methods
				function hide(obj)
						set(obj.hFig,'Visible','off')
						stop(obj)
				end				
				function unhide(obj)
						start(obj)
						set(obj.hFig,'Visible','on')
						figure(obj.hFig)
				end
		end
		methods (Hidden)
				function openFigure(obj)
						if isempty(obj.hFig)
								obj.hFig = figure;
						end
						if isempty(obj.hAx)
								obj.hAx = gca;
						end
				end
				function hideDontClose(obj,src,evnt)
						set(src,'visible','off')
				end
				function delete(obj)
						delete(obj.hFig)
				end
		end
		
		
		
end
