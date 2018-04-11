classdef UdpDelayAssessment < hgsetget
   
   properties
      udpObj
      timerObj
      calUdpObj
      udpDelay
      displayOn
      plotOn
   end
   properties (SetAccess = protected)
      nRcvd
      plotFig
      plotAx
      plotData
      plotFig2
      plotAx2
      plotData2
      sendTime
      rcvTime
      sendFrame
      rcvFrame
      localDelay
   end
   properties (Dependent, SetAccess = protected)
      avgDelay
   end
   
   
   
   methods
      function obj = UdpDelayAssessment()
      obj.udpObj = udp('image2','localport',9090);
      set(obj.udpObj,...
	  'ReadAsyncMode','continuous',...
	  'InputBufferSize',1024,...
	  'DatagramReceivedFcn',@(src,event)calcDelay(obj,src,event));
      obj.displayOn = false;
      obj.plotOn = true;
      obj.plotFig = figure;
      obj.plotAx = gca;
      plot([10:.1:11;10.2:.1:11.2]');
      obj.plotData = get(gca,'children');
      set(obj.plotData,'EraseMode','xor')
      set(obj.plotAx,'XLimMode','manual','YLimMode','auto')
      set(obj.plotFig,'HandleVisibility','callback');
      obj.plotFig2 = figure;
      obj.plotAx2 = gca;
      plot([10:.1:11;10.2:.1:11.2]');
      obj.plotData2 = get(gca,'children');
      set(obj.plotData2,'EraseMode','xor')
      set(obj.plotAx2,'XLimMode','manual','YLimMode','auto')
      set(obj.plotFig2,'HandleVisibility','callback');
      if ~obj.plotOn
	  set(obj.plotFig,'visible','off');
      end
      obj.nRcvd = 1;
      obj.sendFrame = 1;
      obj.rcvFrame = 1;
      % Calibration Timer
      obj.calUdpObj = udp('image3',3050,'localport',3050,...
	  'ReadAsyncMode','continuous',...
	  'DatagramReceivedFcn',@(src,event)calibrateUdpOnFrame(obj,src,event));
      fopen(obj.calUdpObj);
      obj.timerObj = timer(...
	  'ExecutionMode','fixedRate',...
	  'TimerFcn',@(src,event)sendUdpOnFrame(obj,src,event),...
	  'BusyMode','Queue',...
	  'Period',.033);
      fopen(obj.udpObj);
      start(obj.timerObj)
      end
      
      function delete(obj)
      fclose(obj.udpObj);
      delete(obj.udpObj)
      delete(obj.timerObj)
      fclose(obj.calUdpObj);
      delete(obj.calUdpObj)
      end
      
      function stop(obj)
      fclose(obj.udpObj);
      stop(obj.timerObj)
      end
      
      function reset(obj)
      fopen(obj.udpObj);
      start(obj.timerObj)
      end
      
      function calcDelay(obj,src,~)
      msgRcvdTime = clock;
      msg = fscanf(src,'%f');
      localTime = msgRcvdTime(5)*60+msgRcvdTime(6);
      obj.udpDelay(obj.nRcvd) = localTime - msg;
      if obj.displayOn
      disp(['Message: ',num2str(msg)])
      disp(['Time: ',num2str(localTime)]);
      disp(['Difference: ',num2str(obj.udpDelay(obj.nRcvd))]);
      disp('');
      end
      if obj.plotOn
	  plotDelay(obj)
      end
      obj.nRcvd = obj.nRcvd+1;
      end
      
      function sendUdpOnFrame(obj,src,event)
      c = clock;
      obj.sendTime(obj.sendFrame) = c(6);
      fprintf(obj.calUdpObj,'%f',obj.sendTime(obj.sendFrame));
      obj.sendFrame = obj.sendFrame+1;
      end
      
      function calibrateUdpOnFrame(obj,src,event)
      c = clock;
      obj.rcvTime(obj.rcvFrame) = fscanf(obj.calUdpObj,'%f');
      obj.localDelay(obj.rcvFrame) = obj.rcvTime(obj.rcvFrame)-c(6);
       if obj.plotOn
	  plotDelay2(obj)
      end
      obj.rcvFrame = obj.rcvFrame+1;
      end
      
      function plotDelay(obj)
      if length(obj.udpDelay)<1000
	  set(obj.plotData,'YData',obj.udpDelay,...
	     'XData',1:length(obj.udpDelay),...
	     'LineWidth',1)
	  set(obj.plotAx,'XLim',[1 10*round(length(obj.udpDelay)+10)/10+10])
      else
	  try
	     set(obj.plotData,'YData',obj.udpDelay((end-999):end),...
		 'XData',length(obj.udpDelay)-999:length(obj.udpDelay),...
		 'LineWidth',1)
	     set(obj.plotAx,'XLim',[length(obj.udpDelay)-1000 length(obj.udpDelay)+100])
	  catch me
	     disp(me.message) 								disp(me.stack(1))
	  end
      end
      end
      
      function plotDelay2(obj)
      if length(obj.localDelay)<1000
	  set(obj.plotData2,'YData',obj.localDelay,...
	     'XData',1:length(obj.localDelay),...
	     'LineWidth',1)
	  set(obj.plotAx2,'XLim',[1 10*round(length(obj.localDelay)+10)/10+10])
      else
	  try
	     set(obj.plotData2,'YData',obj.localDelay((end-999):end),...
		 'XData',length(obj.localDelay)-999:length(obj.localDelay),...
		 'LineWidth',1)
	     set(obj.plotAx2,'XLim',[length(obj.localDelay)-1000 length(obj.localDelay)+100])
	  catch me
	     disp(me.message) 								disp(me.stack(1))
	  end
      end
      end
      
      
      function avgdelay = get.avgDelay(obj)
      avgdelay = mean(obj.udpDelay);
      end
   end
   
   
   
   
end




