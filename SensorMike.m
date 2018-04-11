classdef SensorMike < hgsetget
    
    
    
    properties(GetAccess = public)
        id
        x
        y
    end
    properties (Dependent)
        dx
        dy
    end
    
    methods
        function obj = Sensor(sens)
            %constructor; initializes everything to zeroes
            fprintf('Creating %s sensor\n',sens)
            obj.id = sens;
            obj.dx = 0;
            obj.dy = 0;
            obj.x = 0;
            obj.y = 0;
			obj.lastReadTimeDx = hat;
			obj.lastReadTimeDy = hat;
        end
    end
    methods % SET & GET
        function set.dx(obj,newDx)
            % Adds dx to x
            obj.x = obj.x + newDx;
        end
        function set.dy(obj,newDy)
            % Adds dy to y
            obj.y = obj.y + newDy;
		end
		function dxval = get.dx(obj)
			timeSinceLastRead = hat - obj.lastReadTimeDx;
			dxval = obj.x / timeSinceLastRead;
            disp(dxval);
			obj.lastReadTimeDx = hat;
		end
		function dyval = get.dy(obj)
			timeSinceLastRead = hat - obj.lastReadTimeDy;
			dyval = obj.y / timeSinceLastRead;
			obj.lastReadTimeDy = hat;
		end
        function xval = get.x(obj)
            % Resets x to zero
            xval = obj.x;
            obj.x = 0;			
        end
        function yval = get.y(obj)
            % Resets y to zero
            yval = obj.y;
            obj.y = 0;
        end
    end    
end    














