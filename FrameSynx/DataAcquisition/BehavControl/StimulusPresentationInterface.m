classdef StimulusPresentationInterface < hgsetget
    % ---------------------------------------------------------------------
    % StimulusPresentationInterface
    % FrameSynx Toolbox
    % 1/8/2010
    % Mark Bucklin
    % ---------------------------------------------------------------------
    % 
    % This class defines a standard set of properties and events that any
    % derived class should implement in order to maintain compatibility
    % with the rest of the FrameSynx system.
    %
    % See Also BEHAVCONTROLINTERFACE, BEHAVIORSYSTEM, BEHAVCONTROL,
    % FRAMESYNX
      
		
		
		
      
      properties (SetAccess = protected, AbortSet, SetObservable)
            stimState = 'stim on';
            stimStatus = 0;% Increments to 1, 2, 3... resets to 0 at end of Trial
            stimNumber = NaN;
            experimentState = 'pause';
            currentTrialNumber = 0;
            lastMsgRcvd;
            lastMsgRcvTime
            codeTable
            logFile
            logFileName
						fileName
			end
			properties (Transient)
					gui
			end
      
			
			
			events
					ExperimentStart
					ExperimentStop
					NewTrial
					NewStimulus
			end
			
			
			
      
      methods (Abstract, Access = protected)
            messageReceivedFcn(varargin)
      
      end
      methods (Static)
            function codeTable = defineCodeTable()
                  tmp = cell(2,4);
                  tmp{1,1} = 'stim on';
                  tmp{1,2} = 'stim shift';
                  tmp{1,3} = 'stim off';
                  tmp{1,4} = 'stim: ';
                  tmp{2,1} = 'pause exp';
                  tmp{2,2} = 'unpause';
                  tmp{2,3} = 'finished';
                  tmp{2,4} = 'start exp';
                  codeTable = tmp;
                  clear tmp
            end
            
      end
      
      
end
