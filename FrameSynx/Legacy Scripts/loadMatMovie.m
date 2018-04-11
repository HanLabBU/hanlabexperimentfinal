%
% LOADMATMOVIE loads data from a Mat movie file
%   F = LOADMATMOVIE(fileName) loads the file with the specified
%   name and returs the frames (if any)
%
%   [F,T,S,C] = LOADMATMOVIE(fileName) returns also the file's
%   type, and the 'soft' and 'cost' chunks (from the Val files)
%
%   [F,T,S,C,I] = LOADMATMOVIE(fileName) returns also the file's
%   images (the new format of mat files has images separate from
%   frames.
%
function [frames,type,soft,cost,images] = loadMatMovie(fileName)

if ~ischar(fileName)
    error([mfilename ': fileName must be a string']);
elseif ~exist(fileName)
    error([mfilename ': file --> ' fileName ' does not exist']);
else
    vars = whos('-file',fileName);
    nent = length(vars);
end

if nent == 0
    error([mfilename ': file ' fileName ' is empty or is not a valid ''.mat'' file']);
end

hasFrames = 0; hasType = 0; hasSoft = 0; hasCost = 0;
for m = 1:nent
    switch vars(m).name
    case 'frames'
        hasFrames = 1;
    case 'type' % for future versions
        hasType = 1;
    case 'soft'
        hasSoft = 1;
    case 'cost'
        hasCost = 1;
    case 'images'
        hasImages = 1;
    end
end

type = []; soft = []; cost = []; images = [];

if hasType
    type = load(fileName,'type');
    type = type.type;
else
    warning([mfilename ': file ' fileName ' does not have ''type'' descriptor']);
end

if hasFrames
    frames = load(fileName,'frames');
    frames = frames.frames;
else
    error([mfilename ': file ' fileName ' does not have a ''frames'' struct']);
end

if hasSoft
    soft = load(fileName,'soft');
    soft = soft.soft;
else
    warning([mfilename ': file ' fileName ' does not have a ''soft'' struct']);
end

if hasCost
    cost = load(fileName,'cost');
    cost = cost.cost;
else
    warning([mfilename ': file ' fileName ' does not have a ''cost'' struct']);
end

if hasImages
    images = load(fileName,'images');
    images = images.images;
end