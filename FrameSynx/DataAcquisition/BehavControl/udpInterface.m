classdef udpInterface < hgsetget
    
    properties
        remoteIP = '155.41.8.211'
        remoteHost = 'BME-HAN-VR1.AD.BU.EDU'
        remotePort = 9090
        localPort = 9091
        udpListener
        deltas
        sensors = {'l','r'}
    end
    
    properties (SetObservable)
        l
        r
    end
    
    
    methods
        
        function obj = udpInterface(varargin)
            if nargin > 1
                for i = 1:2:length(varargin)
                    obj.(varargin(i))= obj.(varargin(i+1));
                end
            else
                if isempty(obj.remoteHost)
                    obj.remoteHost = 'bme-han-vr1';
                end
                if isempty(obj.remoteIP)
                    [obj.remoteHost, obj.remoteIP] = resolvehost(obj.remoteHost);       %lookup ip-address of computer sending data
                else
                    [obj.remoteHost, obj.remoteIP] = resolvehost(obj.remoteIP);         %lookup hostname of computer sending data
                end
                obj.udpListener = udp(obj.remoteIP,obj.remotePort,'LocalPort',obj.localPort);       % Create UDP-object using Built-In MATLAB command
            end
            set(obj.udpListener,...
                'DatagramReceivedFcn',@(src,event)messageReceivedFcn(obj,src,event),...
                'Name',strcat('udp',obj.localPort),...
                'DatagramTerminateMode','on',...
                'ReadAsyncMode','continuous',...
                'InputBufferSize',2^12,...
                'ByteOrder','bigEndian');
            obj.start;
            
            for i = 1:length(obj.sensors)
                disp(obj.sensors{i})
                obj.(obj.sensors{i}) = Sensor(obj.sensors{i});
            end
            
        end
        
        
        function d = messageReceivedFcn(obj,~,~)
            d = '';
            %             boo = true;
            try
                d = char(fread(obj.udpListener));
                %                 while boo
                %                     newd = char(fread(obj.udpListener,1));
                %                     d = strcat(d,newd);
                %                     if strcmp(newd, ')')
                d = d(:)';  % make character array horizontal
                d = obj.parsedeltas(d);%',d);
            catch err
                %                 keyboard
                disp(err)
            end
        end
        
        function start(obj)
            try
                disp('starting listener')
                fopen(obj.udpListener);
                disp('started!')
            catch err
                disp(err);
            end
        end
        
        function stop(obj)
            try
                disp('stopping...')
                fclose(obj.udpListener);
                disp('stopped!')
            catch err
                disp(err);
            end
        end
        
        function d = parsedeltas(obj,d)
            if isempty(d)
                d = NaN;
                return
            end
            sensorside = d(2);
            x_index = regexp(d,'[x]*');
            y_index = regexp(d,'[y]*');
            dx = str2double(d(x_index+1:y_index-1));
            dy = str2double(d(y_index+1:end-1));
            if isa(dx,'double') && isa(dy,'double')
                obj.(sensorside).dx = dx;
                obj.(sensorside).dy = dy;
                %                 fprintf('%s %d %d \n',obj.(sensorside).side,obj.(sensorside).dx,obj.(sensorside).dy)
            end
            fprintf('%s %d %d \n',obj.(sensorside).side,obj.(sensorside).dx,obj.(sensorside).dy)
        end
        
    end
end
