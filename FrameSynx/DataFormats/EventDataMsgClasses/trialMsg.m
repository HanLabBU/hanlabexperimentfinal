classdef trialMsg < event.EventData
		
		properties
				currentTrial
				previousTrial
		end
		
		methods
				function eventData = trialMsg(currenttrial,varargin)
						try
								eventData.currentTrial = currenttrial;
								if nargin>1
										eventData.previousTrial = varargin{1};
								end
						catch
								warning('NewTrial:trialMsg:NoEventData','No NewTrial event-data set');
						end
				end
		end
		
end
