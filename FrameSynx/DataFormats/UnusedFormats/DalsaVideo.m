classdef DalsaVideo < uint16
		
		
		
		properties (SetAccess = protected)
				bitDepth
		end
		properties
				time
				absTime
				frameNumbers
		end
		
		
		%NOTE: This file may need fixes for indexing into framesyncdata
		
		methods
				function obj = DalsaVideo(userinput)
						try
								switch lower(class(userinput))
										case 'struct' % structure returned by Camera>getAllData() function
												if isfield(userinput,'vid')
														viddata = userinput.vid;
												end
										case 'cell' % TODO: add support for cells
										case 'trial' %casting trial to extract its video
												viddata = cat(4,userinput.video); %concatenates video if input is an array of trials
										case 'experiment'
												viddata = cat(4,userinput.trialSet.video);
										case 'dalsavideo'
												viddata = userinput.Data;
										otherwise
												if isnumeric(userinput)
														viddata = userinput;
												else
														error('DataType is not acceptable')
												end
								end
								viddata = DalsaVideo.format(viddata);
						catch me
								warning(me.message)
								disp(me.stack(1))
						end
						obj = obj@uint16(viddata);
						obj = checkInput(obj,userinput);
						obj.bitDepth = 16;
				end
				function obj = checkInput(obj,userinput)
						try
								switch lower(class(userinput))
								case 'struct'
										obj.time = userinput.time;
										obj.absTime = cat(1,userinput.meta.AbsTime);
										obj.frameNumbers = cat(1,userinput.meta.FrameNumber);
								case 'trial'
										framesyncdata = userinput.frameSyncData;
										obj.time = cat(1,userinput.frameTimes);
										obj.absTime = cat(1,framesyncdata.AbsTime);
										obj.frameNumbers = cat(1,framesyncdata.FrameNumber);
								case 'experiment'
										framesyncdata = userinput.frameSyncData;
										obj.time = cat(1,userinput.trialSet.frameTimes);
										obj.absTime = cat(1,framesyncdata.AbsTime);
										obj.frameNumbers = cat(1,framesyncdata.FrameNumber);
								case 'dalsavideo'
										obj.time = userinput.time;
										obj.absTime = userinput.absTime;
										obj.frameNumbers = userinput.frameNumbers;
								end
						catch me
								warning(me.message)
								disp(me.stack(1))
						end
				end
				function showFrame(obj,framenum)
						if nargin < 2
								framenum = 1;
						end
						data = uint16(obj);
						hFig = figure;
						colormap(gray)
						imagesc(data(:,:,:,framenum));%TODO: use class defined indexing
						set(gca,...
								'position',[0 0 1 1],...
								'UserData',framenum);
						set(hFig,...
								'ResizeFcn','axis fill')
						axis image off tight fill
						brighten(.1)
				end			
		end
		methods % Pseudo-Get Methods
				function res = resolution(obj)
						sz =  size(uint16(obj));
						res = [sz(1) sz(2)];% [numrows numcolumns]						
				end
				function nchannels = numchannels(obj)
						nchannels = size(uint16(obj),3);
				end
				function timeduration = duration(obj)
						timeduration = obj.time(end) - obj.time(1);
				end
		end
		methods (Static)
				function [data,varargout] = format(data)
						% [reformattedData, originalDataType, newDataType]
						bitsize = 16;
						maxint = 2^bitsize - 1;
						if nargout > 1
								varargout{1} = class(data);
						end
						if nargin == 0
								data = uint16([]);
						else
								if ~strcmp('uint16',class(data))
								% If image data is not uint16, convert to uint16
								switch lower(class(data))
										case 'dalsavideo'
												data = uint16(data);
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
												elseif ~isempty(data)
														% stretch to use full 16-bit scale
														tmp = data + min(data(:));
														data = uint16((tmp ./ max(tmp(:))) * maxint);
												else
														data = uint16(data);
												end
										otherwise
												error('Not a supported image class')
								end
								end
								switch length(size(data))
										% Reshape to conform to standard dimensions:
										% [ height x width x numchannels x numframes]
										case 3 
												if size(data,3) > 3 % assume no channels dimension
														data = reshape(data, [ size(data,1) size(data,2)   1   size(data,3)]);
												else % assume this is a single frame of multiple-channel data
														data = reshape(data, [ size(data,1) size(data,2) size(data,3)    1   ]);
												end
										case 2 
												if size(data,1) > 9999 % assume old format where each frame is in a column
														likelyresolution = sqrt(size(data,1));
														if round(likelyresolution) ~= likelyresolution
																error('What kind of data is this? The dimensions are all wrong');
														end
														data = reshape(data,[likelyresolution likelyresolution 1 size(data,2)]);
												else % assume this is a single frame of data
														data = reshape(data,[size(data,1) size(data,2)    1     1 ]);
												end
								end%TODO add support for checking rotation?
						end
						if nargout > 2
								varargout{2} = class(data);
						end
				end
		end
		methods % Must Implement Methods
					function sref = subsref(obj,s)
						% Implements dot notation for DataString and Data
						% as well as indexed reference
						switch s(1).type
								case '.'
										switch lower(s(1).subs)
												case 'frame'
														try
																n = s(2).subs{:};
																ss.type = '()';
																ss.subs = {':',':',':',n};
																sref = subsref@DalsaVideo(obj,ss);
																% 														sf = uint16(obj);
																% 														sref = DalsaVideo(sf(:,:,:,cell2mat(s(2).subs)));
																%TODO: fix this, getting index exceeds matrix dimensions error
																if length(s) > 2
																sref = subsref(sref,s(3:end));
														end
														catch me
																warning('Could not get channel');
																sref = [];
														end
												case 'channel'
														n = s(2).subs{:};
																ss.type = '()';
																ss.subs = {':',':',n,':'};
																sref = subsref@DalsaVideo(obj,ss);
														% 														sref = obj(:,:,cell2mat(s(2).subs),:);
														% 														sf = uint16(obj);
														% 														sref = DalsaVideo(sf(:,:,cell2mat(s(2).subs),:));
														if length(s) > 2
																sref = subsref(sref,s(3:end));
														end
												otherwise
														switch lower(s(1).subs)
																case 'resolution'
																		sref = obj.resolution;
																case 'numchannels'
																		sref = obj.numchannels;
																case 'duration'
																		sref = obj.duration;
																case 'time'
																		sref = obj.time;
																case 'abstime'
																		sref = obj.absTime;
																case 'framenumbers'
																		sref = obj.frameNumbers;
																case 'bitdepth'
																		sref = obj.bitDepth;
														end
														if length(s)>1 && strcmp(s(2).type, '()')
																sref = subsref(sref,s(2:end));
														end
										end
								case '()'
										sf = uint16(obj);
										if ~isempty(s(1).subs)
												sf = subsref(sf,s(1:end));
										else
												error('Not a supported subscripted reference')
										end
										if length(s(1).subs) >2
												chans = s(1).subs{3};
												if ischar(chans) % is either : or end?
														switch chans
																case ':'
																		chans = 1:size(obj,3);
																case 'end'
																		keyboard
														end
												end
												frames = s(1).subs{4};
												if ischar(frames) % is either : or end?
														switch frames
																case ':'
																		frames = 1:size(obj,4);
																case 'end'
																		keyboard
														end
												end
												vidinput.time = obj.time(frames,chans);
												vidinput.meta.AbsTime = obj.absTime(frames,chans);
												vidinput.meta.FrameNumber = obj.frameNumbers(frames,chans);
												vidinput.vid = sf;
										else
												vidinput = sf;
										end
										sref = DalsaVideo(vidinput);
						end
				end
		end
end


% if properties are defined, we should redefine subsref, horzcat, and vertcat methods, because
% superclass default methods will not work by default











