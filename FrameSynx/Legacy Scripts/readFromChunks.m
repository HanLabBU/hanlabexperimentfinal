%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% readFromChunks.m - The holy data retrieval function.  Mostly a conversion
%   of pre-existing "getFramesFromSequence", which retrieves frames from 
%   a continuous sequence, returning the frames falling in the interval R
%   for the given fileSequence.  This one also optionally gets only a
%   part of the image, input as a vector.
%
%   R(1) should be the first frame desired and R(2) should be
%   the last frame desired.
%
%   If R = [], the range will be all frames, as found in the first chunk.
%
%   1 "chunk" = 1 section of 1 frame, over all trials.
%   
%   02.12.09 - Started.
%   02.17.09 - Comments... fixing... works for one chunk!
%   02.19.09 - Spent like the whole day trying to get it to work for 
%      chunkDatas with multiple parts, but then decided it was a nightmare.
%      My converter will have to make them into 1 "part" apparently.
%      Boy did that made things a hell of a lot easier.
%   03.02.09 - Tried to get it to work for rectangular (non-continuous)
%      chunks, but failed...
%   03.04.09 - Gene to the rescue, found the one faulty variable.  Works!!
%   03.06.09 - Rewrote to avoid loading a too-huge empty matrix into memory.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function I = readFromChunks(fileSequence, R, position)

% profile on
%I should rewrite this to use Gene's nargin system.  Sometime.
if nargin < 3
    fprintf('\n---No position specified, going with ALL pixels.---\n');
    position = 1:265*256;
end

positionInds = find(position);
if isempty(R)
    fprintf('\n---No range specified, going with ALL frames.---\n');
    R(1) = fileSequence(1).first_frame;
    R(2) = fileSequence(1).last_frame;
end

%% Test some bounds
%Lists of frame numbers.  Should all be either 1 or 31138...
frame_beginnings = [fileSequence.first_frame];
frame_endings = [fileSequence.last_frame];
if R(1)<frame_beginnings(1) || R(2)>frame_endings(end)
    error([mfilename ': requested frame range out of bounds']);
end

%Lists of position numbers.  These should definitely vary.
pos_beginnings = [fileSequence.first_position];
pos_endings = [fileSequence.last_position];
if (min(positionInds) < pos_beginnings(1)) || (max(positionInds) > pos_endings(end))
    error([mfilename ': requested position out of bounds']); %This kinda assumes that positions increase monotonically
end


%% Decide which files (chunks) you need to access.
% Grab file numbers based on POSITION, which is defined in the fileInfo!!!
the_right_chunks = [];
for n = 1:length(fileSequence)
    if ~isempty(intersect(fileSequence(n).position,positionInds))
        the_right_chunks = [the_right_chunks n]; %#ok<AGROW>
    end
end

% firstPosRow = ceil(min(positionInds)/256);
% lastPosRow = ceil(max(positionInds)/256);
% firstPosY = ceil(firstPosRow / (256/chunks_y));
% lastPosY = ceil(lastPosRow / (256/chunks_y));
% 
% firstPosCol = mod(min(positionInds)-1,256)+1;
% lastPosCol = mod(max(positionInds)-1,256)+1;
% firstPosX = ceil(firstPosCol / (256/chunks_x));
% lastPosX = ceil(lastPosCol / (256/chunks_x));

%% Grab the data!

% Allocate memory!  Now in small-as-possible shape.
fprintf('\nAllocating some memory...')
I = zeros(length(positionInds),length(R(1):R(2))); %The output.  D1 is pos, D2 is time/frames.
fprintf(' Done!\n');

% Start loop through the necessary chunks!
for thisChunk = the_right_chunks
    fprintf(['Reading from file/chunk number ' num2str(thisChunk) '... ']);
    vars = whos('-file',fileSequence(thisChunk).name); %Get a struct about the variables in the mat file
    data_vars = vars(strmatch('chunkData',{vars.name})); %the "chunkData" variable in the mat
    nParts = length(data_vars); %size of image struct
    if nParts > 1; error('Shits, multi-part "images" mats (i.e. images2) not yet supported!!!')
    elseif nParts == 0; error('Whoa!  No parts!')
    end

    %Grab frame numbers for this file.
    file_frame_inds = frame_beginnings(thisChunk):frame_endings(thisChunk); %Grab all frame numbers for this file.  Should really be 1:31138!!
    target_frames = find(file_frame_inds>=R(1) & file_frame_inds<=R(2)); %#ok<NASGU> %Trim to the trigger/window

    %Grab position numbers for this file.
    thisChunkInds = fileSequence(thisChunk).position;
    [target_pos_inds_InImgCoords,target_pos_inds_InChunkCoords,target_pos_inds_InTargetCoords] = intersect(thisChunkInds,positionInds); %#ok<NASGU> ChunkCoords gets used in an eval
    
    %Load the proper image-part.
    fprintf('(Loading)');
    clear(data_vars(1).name);
    
    load(fileSequence(thisChunk).name,data_vars(1).name); %data_vars(1) 'cause there's only 1 part.

    %"I", the output, grabs the appropriate data from "chunkData", or whatever the thing's called.
    fprintf('\b\b\b\b\b\b\b\b\b\b(Writing)');
    I(target_pos_inds_InTargetCoords,:) = eval([data_vars(1).name '(target_pos_inds_InChunkCoords,target_frames)']);
    fprintf('\b\b\b\b\b\b\b\b\b-Done!-\n');
    
end

fprintf('\n ReadFromChunks finished!!\n\n');
% profile report
% profile off