% GETFRAMESFROMSEQUENCE   Retrieve frames from continuous sequence
%   I = getFramesFromSequence(fileSequence,R) returns the frames
%   falling within range R for the given fileSequence.
%
%   R(1) should be the first frame desired and R(2) should be
%   the last frame desired.
%
%   I = getFramesFromSequence(fileSequence,R,'arg1','val1','arg2','val2'...)
%   where args can be:
%       'filter' * does a boxcar filter on the timeseries of 
%                  width supplied in the value
%
function I = getFramesFromSequence(fileSequence,R,varargin)

filter_err = [0 0];

filter_size = 0;
for n = 1:2:length(varargin)
    switch varargin{n}
    case 'filter'
        filter_size = varargin{n+1};
        if ~mod(filter_size,2)
            fprintf('%s: increasing boxcar filter size from %i to %i so that it is an odd number\n',mfilename,filter_size,filter_size+1);
            filter_size = filter_size + 1;
        end
    otherwise
        error([mfilename ': unknown argument ' varargin{n}]);
    end
end

filter_buff = floor(filter_size/2);

beginnings = [fileSequence.first_frame];
endings = [fileSequence.last_frame];

R(1) = R(1)-filter_buff;
if R(1) < 1
    fprintf('%s: cannot adjust start range %i to account for filter\n',mfilename,R(1)+filter_buff);
    fprintf('%s: expect edge artifact\n',mfilename);
    filter_err(1) = abs(R(1))+1;
    R(1) = 1;
end    

if R(2)>endings(end)
    error([mfilename ': requested frame range out of bounds']);
end
    
R(2) = R(2)+filter_buff;
if R(2)>endings(end)
    fprintf('%s: cannot adjust end range %i to account for filter\n',mfilename,R(2)-filter_buff);
    fprintf('%s: series truncated to frame %i\n',mfilename,R(2)-filter_buff*2);
    filter_err(2) = R(2)-endings(end);
    R(2) = endings(end);
end

firstFile = max(find(beginnings<=R(1)));
lastFile = max(find(beginnings<=R(2)));

load(fileSequence(firstFile).name,'first_image');

% allocate for sequence
I = zeros(size(first_image,1),length(R(1):R(2)));

cur_pos = 1;
for n = firstFile:lastFile
    vars = whos('-file',fileSequence(n).name);
    image_vars = vars(strmatch('images',{vars.name}));
    nChunks = length(image_vars);
    chunkSize = cell2mat({image_vars.size}');
    chunk_endings = cumsum(chunkSize(:,2))';
    chunk_beginnings = [1 chunk_endings(1:end-1)+1];
    
    file_inds = beginnings(n):endings(n);
    inds = find(file_inds>=R(1) & file_inds<=R(2));    
    
    firstChunk = min(find(chunk_endings>=inds(1)));
    lastChunk = min(find(chunk_endings>=inds(end)));
    
    cur_chunk_pos = 0;
    for c = firstChunk:lastChunk
        load(fileSequence(n).name,image_vars(c).name);
        chunk_inds = chunk_beginnings(c):chunk_endings(c);
        inds1 = find(chunk_inds>=inds(1) & chunk_inds<=inds(end));
        I(:,[cur_pos:cur_pos+length(inds1)-1]+cur_chunk_pos) = eval([image_vars(c).name '(:,inds1)']);
        cur_chunk_pos = cur_chunk_pos + length(inds1);
    end
    
    cur_pos = cur_pos + length(inds);
    clear images;
end

if filter_size
    flt = ones(1,filter_size);
    I = filter(flt,filter_size,I,[],2);
    I = I(:,filter_size-filter_err(1):end);    
end
        