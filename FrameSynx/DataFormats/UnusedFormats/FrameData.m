classdef FrameData < handle
		
		
		
		properties % Frame Info & Data
				number
				time
				channel
				data
		end
		
		
		
		
		
		methods
				function obj = FrameData(varargin)
						if nargin > 1
								for k = 1:2:length(varargin)
										obj.(varargin{k}) = varargin{k+1};
								end
						end
						
				end
		end
		
		
		
end
		
		
