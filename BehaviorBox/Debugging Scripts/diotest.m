function diotest(src,evnt)
dio = src;
val = getvalue(dio.Line(1:8));
fprintf('%i%i%i%i%i%i%i%i\n',val(:));


% if val
%     fprintf('port 1 bit 0')
% else
% %     fprintf('nada')
% end






%src
%         Line = [1x1 dioline]
%                Index:  LineName:  HwLine:  Port:  Direction:  
%                   1       ''         0        1      'In'        
%         Name = nidaqmxDev1-DIO
%         Running = On
%         Tag = 
%         TimerFcn = @diotest
%         TimerPeriod = 0.1
%         Type = Digital IO
%         UserData = []


%evnt
%  Type: 'Timer'
%  Data: [1x1 struct]
%    AbsTime: [2011 7 15 17 49 48.5237]