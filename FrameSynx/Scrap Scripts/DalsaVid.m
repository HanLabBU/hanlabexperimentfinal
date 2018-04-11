classdef DalsaVid < uint16
		
		
		properties
				resolution
				channels
		end
		properties % vectors 
				time
				absTime
				frameNumber
		end
		
		
		
		
		
		methods
				function obj = DalsaVid(data)
						data = checkDataType(data);
						
						obj = obj@uint16(data);
				end				
				function h = showImage(obj)
						data = uint8(obj);
						figure; colormap(gray(256))
						h = imagesc(data,[0 255]);
						axis image
						brighten(.2)
				end
				function sref = subsref(obj,s)
         % Implements dot notation for DataString and Data
         % as well as indexed reference
         switch s(1).type
            case '.'
               switch s(1).subs
                  case 'DataString'
                     sref = obj.DataString;
                  case 'Data'
                     sref = double(obj);
                     if length(s)>1 && strcmp(s(2).type, '()')
                        sref = subsref(sref,s(2:end));
                     end
               end
            case '()'
               sf = double(obj);
               if ~isempty(s(1).subs)
                  sf = subsref(sf,s(1:end));
               else
                  error('Not a supported subscripted reference')
               end
               sref = DocExtendDouble(sf,obj.DataString);
         end
      end
		end
		
		methods (Static)
				function [data,varargout] = checkDataType(data)
						% [reformattedData, originalDataType, newDataType]
						bitsize = 16;
						maxint = 2^bitsize - 1;
						if nargout > 1
								varargout{1} = class(data);
						end
						if nargin == 0
								data = uint16([]);
								% If image data is not uint16, convert to uint16
						elseif ~strcmp('uint16',class(data))
								switch class(data)
										case 'uint8'
												% scale the data up to fill bit-depth
												tmp = double(data)/255;
												data = uint16(tmp * maxint);
										case 'double'
												if any(data > maxint)
														% scale down to fit 16-bit bit-depth
														tmp = data ./ max(data(:));
														data = uint16(round(tmp .* maxint));
												elseif any(data(:) > 1) && all(data(:) > 0)
														% assume data isn't scaled from 0 to 1
														data = uint16(data);
												else
														% stretch to use full 16-bit scale
														tmp = data + min(data(:));
														data = uint16((tmp ./ max(tmp(:))) * maxint);
												end
										otherwise
												error('Not a supported image class')
								end
						end
						if nargout > 2
								varargout{2} = class(data);
						end
				end
		end
		
end


% if properties are defined, we should redefine subsref, horzcat, and vertcat methods, because
% superclass default methods will not work by default
