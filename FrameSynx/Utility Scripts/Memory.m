classdef Memory < handle
		
		
		
		
		properties (Dependent, SetAccess = private)
				
		end
		
		
		
		
		methods (Static)
				function gb = virtual()
						% 						[userview systemview] = memory;
						[~,systemview] = memory;
						gb = systemview.VirtualAddressSpace.Available/2^30;
				end
				function gb = physical()
						[~,systemview] = memory;
						gb = systemview.PhysicalMemory.Available/2^30;
				end
				function gb = maxArray()
						[userview ,~] = memory;
						gb = userview.MaxPossibleArrayBytes/2^30;
				end
		end
		
		
		
		
		
		
		
		
end









