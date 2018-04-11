classdef TouchInterface < hgsetget
    % ---------------------------------------------------------------------
    % TouchInterface
    % Han Lab
    % 7/11/2011
    % Mark Bucklin & Chun Hin Tang
    % ---------------------------------------------------------------------
    %
    % This class implements an interface to the IRTouch Touchscreen using
    % serial communication via the RS232 port.
    %
    % See Also TOUCHDISPLAY RECTANGLE POSITIONDATA
    
    
    
    
    properties
        serialObj
        serialTag
        serialPort
    end
    properties (SetObservable, SetAccess = protected)
        lastPosition
        istouched
        isready
    end
    properties (Hidden, Transient) % Settings
        timeout
        touchListener
    end
    properties
        default
    end
    
    
    
    
    
    events
        TouchStart
        TouchData
        TouchStop
    end
    
    
    
    
    
    methods % Initialization
        function obj = TouchInterface(varargin)
            if nargin > 1
                for k = 1:2:length(varargin)
                    obj.(varargin{k}) = varargin{k+1};
                end
            end
            obj.isready = false;
            obj.default = struct(...
                'serialPort','COM3',...
                'serialTag','irtouch');
        end
        function setup(obj)
            try
                % Fill in Defaults
                props = fields(obj.default);
                for n=1:length(props)
                    thisprop = sprintf('%s',props{n});
                    if isempty(obj.(thisprop))
                        obj.(thisprop) = obj.default.(thisprop);
                    end
                end
                % Check Serial Port Number
                obj.setComFcn();
                % Look for previously constructed serial objects
                obj.serialObj = instrfind('Type', 'serial',...
                    'Port', obj.serialPort,...
                    'Tag',obj.serialTag);
                % Construct the Serial object
                if isempty(obj.serialObj) || ~isvalid(obj.serialObj)
                    obj.serialObj = serial(obj.serialPort,...
                        'BaudRate',9600,...
                        'Tag',obj.serialTag,...
                        'BytesAvailableFcn',@(src,evnt)readSerialFcn(obj,src,evnt),...
                        'BytesAvailableFcnMode','byte',...
                        'BytesAvailableFcnCount',10,...
                        'ErrorFcn',@errorRecoveryFcn);
                else
                    flushinput(obj.serialObj);
                end
                fopen(obj.serialObj);
                obj.isready = true;
                obj.istouched = false;
            catch me
                disp(me)
                warning(me.message)
            end
            function errorRecoveryFcn(src,evnt)
                % This function recovers from read errors generated by the
                % serial port by flushing data in the buffer and restarting
                % the serial object
                flushinput(src)
                if isvalid(src)
                    fclose(src);
                end
                fopen(src);
                warning('Restarting TouchInterface serial port')
            end
        end
        function setComFcn(obj)
            % This function checks to see if the default serial port
            % ('COM1') is available. If it's not available it will assign
            % the available serial port, or in the case of multiple
            % available ports query the user.
            comOptions = instrhwinfo('serial');
            if any(strcmp(obj.serialPort,comOptions.AvailableSerialPorts))
                return
            end
            if length(comOptions.SerialPorts) > 1
                prompt = sprintf('Select COM port for touchscreen:');
                selection = menu(prompt,comOptions.SerialPorts);
                if selection
                    obj.serialPort = comOptions.SerialPorts{selection};
                else
                    obj.serialPort = comOptions.SerialPorts{1};
                end
            else
                obj.serialPort = comOptions.SerialPorts{1};
            end
        end
    end
    methods % Communication Functions
        function readSerialFcn(obj,src,evnt)
            % This function is called automatically when bytes are
            % available via the serial port interface to the IRTouch
            % touchscreen. The protocol was determined using a pdf supplied
            % by Cindy at IRTouch USA, (www.irtouchusa.com). 'src' is the
            % serial object that is calling this function
            if src.BytesAvailable<9
                % note: when moving from one computer to another there was some
                % sort of error generated by this function because the
                % 'BytesAvailableFcnCount' property was set to 9 rather
                % than 10, which was sufficient on the other computer.
                fprintf('readSerialFcn called for only %d bytes\n',src.BytesAvailable)
                return
            end
            % Read lead byte -> should be 55H
            leadbyte = fread(src,1,'uint8');
            if isempty(leadbyte)
                fprintf('blank byte read\n')
                return
            end
            if ~strcmp(dec2hex(leadbyte),'55')
                error('Touchscreen read error: lead byte not 55H')
            end
            
            % Read command byte -> should be 'T'
            commandbyte = fread(src,1,'uchar');
            if commandbyte ~= 'T'
                error('Touchscreen read error: command byte not ''T'' ')
            end
            
            % Read data bytes
            statuscode = dec2bin(fread(src,1,'uint8'));
            x = fread(src,1,'uint16'); % x position, 0 to 4096
            y = fread(src,1,'uint16'); % y position, 0 to 4096
            ffh = fread(src,1,'uint8'); %no clue
            crc = fread(src,1,'uint16'); %error checking?
            switch statuscode
                case '10000001' % Touch starting (finger down)
                    obj.istouched = true;
                    notify(obj,'TouchStart',PositionData([x;y]))
                case '10000010' % Uninterrupted touch event
                    notify(obj,'TouchData',PositionData([x;y]))
                case '10000100' % Touch finished (finger lifted)
                    notify(obj,'TouchStop',PositionData([x;y]))
            end
            obj.lastPosition = [x;y];
        end
    end
    methods % Cleanup
        function delete(obj)
            try
                if ~isempty(obj.serialObj) && isvalid(obj.serialObj)
                    fclose(obj.serialObj);
                    delete(obj.serialObj);
                end
                %                 instrreset
            catch me
                disp(me.message)
                disp(me.stack(1))
            end
        end
    end
    
    
    
end
















