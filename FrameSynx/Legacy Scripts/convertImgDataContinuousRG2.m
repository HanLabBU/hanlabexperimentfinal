%
% CONVERTIMGDATACONTINUOUSREDGREEN converts image data from Val's format to others
%   CONVERTIMGDATACONTINUOUSREDGREEN(fileName,from,to,params) where fileName is the
%   name of the file you want to convert, from is the original file
%   format, to is the desired format, and params describes additional
%   information for the function
%
%   'from' currently only works for value 'Val' (Valeri's) format
%   'to' can be either 'Ani' (Aniruddha's) or 'Mat' (MATLAB's) format
%
%   params is a struct which may have fields:
%       'chunk_size'    <-- size of individual data chunks
%       'source_path'   <-- the path to the file (if not current directory)
%       'dest_path'     <-- the path to which the converted file should be written
%
function convertImgDataContinuousRG(fileName,from,to,params)

DFLT_MAX_FRAMES = Inf;
DFLT_MIN_FRAMES = 0;
DFLT_SOURCE_PATH = './';
DFLT_DEST_PATH = './';
DFLT_DATA_CHUNK_SIZE = 25; % MB

if nargin < 4 % exclude only files that won't fit in memory
    params.max_frames = DFLT_MAX_FRAMES;
    params.min_frames = 0;
    params.dest_path = DFLT_DEST_PATH;
    params.source_path = DFLT_SOURCE_PATH;       
    params.chunk_size = DFLT_DATA_CHUNK_SIZE;
else
    assert('~isstruct(params)',1,[mfilename ': params must be a struct with fields ''max_frames'' and ''min_frames''']);
    
    if ~isfield(params,'max_frames')
        warning([mfilename ': params.max_frames undefined... using default value (' num2str(DFLT_MAX_FRAMES) ')']);
        params.max_frames = DFLT_MAX_FRAMES;
    end
    
    if ~isfield(params,'min_frames')
        warning([mfilename ': params.min_frames undefined... using default value (' num2str(DFLT_MIN_FRAMES) ')']);
        params.min_frames = DFLT_MIN_FRAMES;
    end
    
    if ~isfield(params,'source_path')
        warning([mfilename ': params.source_path undefined... using default value (' DFLT_SOURCE_PATH ')']);
        params.source_path = DFLT_SOURCE_PATH;
    elseif params.source_path(end) ~= '/'
        params.source_path = [params.source_path '/'];
    end
    
    if ~isfield(params,'dest_path')
        warning([mfilename ': params.dest_path undefined... using default value (' DFLT_DEST_PATH ')']);
        params.dest_path = DFLT_DEST_PATH;
    elseif params.dest_path(end) ~= '/'
        params.dest_path = [params.dest_path '/'];
    end
    
    if ~isfield(params,'chunk_size')
        warning([mfilename ': params.chunk_size undefined... using default value (' DFLT_DATA_CHUNK_SIZE ')']);
        params.chunk_size = DFLT_DATA_CHUNK_SIZE;
    end
    
    if ~exist(params.dest_path,'dir')
        warning([mfilename ': params.dest_path does not exist... creating']);
        mkdir(params.dest_path);
    end
end

onFileError = 'fclose(fid)';

% open the original file and test if successful
fprintf('%s: opening file %s\n',mfilename,[params.source_path fileName]);
fid = fopen([params.source_path fileName]);
assert('fid==-1',1,[mfilename ': Could not open file : ' fileName],onFileError);

if strcmp(from,'val')
    convertImgDataFromVal(fid,to,params);
elseif strcmp(from,'ani')
    convertImgDataFromAni(fid,to,params);
elseif strcmp(from,'mat')
    convertImgDataFromMat(fid,to,params);
else
    error([mfilename ': Unknown ''from'' format : ' from '\n']);
end

% close the original file
fclose(fid);

function convertImgDataFromAni(fid,to,params)

function convertImgDataFromMat(fid,to,params)

function convertImgDataFromVal(fid,to,params)

onError = 'fclose(fid)';
onFileError = 'fclose(fid); fclose(outFid);';

[a fromFileRoot] = fileparts(fopen(fid));

if strcmp(to,'mat')
    convertTo = 0;
    toFileName = [params.dest_path fromFileRoot '.mat'];
elseif strcmp(to,'ani')
    convertTo = 1;
    toFileName = [params.dest_path fromFileRoot '.ani'];
elseif strcmp(to,'val')
    fprintf([mfilename ': Nothing to do']);
else
    error([mfilename ': Unknown ''to'' format : ' to '\n']);
end

if ~isempty(dir(toFileName))
    fprintf('%s: Nothing to do for file %s, file already exists\n',mfilename,toFileName);
    return;
end

dataTypeString = '';
fromFileName = fopen(fid);

fprintf('%s: Converting Image %s from VAL to %s file %s\n',mfilename,fromFileName,upper(to),toFileName);

[chunk cof] = readChunk('DATA_CHUNK',fid,1);

if ~strcmp(chunk.ID,'ISOI')
    fclose(fid);
    error('%s: Could not find ISOI fileheader in file %s',mfilename,fopen(fid));
end

fprintf('%s: Got ISOI fileheader from file %s\n',mfilename,fopen(fid));

[soft,softof] = findChunkInFile('SOFT',fid);
assert('isempty(soft)',1,[mfilename ': cannot find SOFT chunk in file ' fromFileName],onError);
soft = readChunk('SOFT_CHUNK',fid);
fprintf('%s: SubjectID is %s\n',mfilename,soft.SubjectID);

[data,cof] = findChunkInFile('DATA',fid);

assert('isempty(data)',1,[mfilename ': cannot find DATA chunk in file ' fromFileName],onError); 
data = readChunk('DATA_CHUNK',fid);
fileHeaderSize = ftell(fid);

tag = soft.Tag;
XYSize = soft.XSize*soft.YSize;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% handle val's tags and determine type of file
%if tag(1)=='G' | tag(1)=='E' & tag(2) == '_' 
%    fprintf('%s: %s is a green image file\n',mfilename,fromFileName);
%    type = 'green';
%        
%    % read in the image and save
%    fseek(fid,fileHeaderSize,'bof');
%    image = reshape(fread(fid,soft.XSize*soft.YSize,dataTypeString),soft.XSize,soft.YSize)';
%    
%    fprintf('%s: Writing %s... ',mfilename,toFileName);
%    switch convertTo
%    case 0 % mat format
%        save(toFileName,'soft','image');
%    case 1 % ani format
%        outFid = fopen(toFileName,'w+');
%        assert('fid==-1',1,[mfilename ': Could not open file : ' toFileName],onFileError);
%        count = count + fwrite(outFid,dataType,'int16');    % data type
%        count = count + fwrite(outFid,soft.XSize,'int16');  % x size
%        count = count + fwrite(outFid,soft.YSize,'int16');  % y size
%        count = count + fwrite(outFid,reshape(image,1,XYSize),dataTypeString); % the green image
%        assert('count==soft.XYSize+3',0,[mfilename ': error writing file'],onFileError);
%        fclose(outFid);
%    end
%    fprintf('Done\n');
%    return;
%elseif tag(1)=='A' | tag(1)=='C' & tag(2) == '_'
%    fclose(fid);
%    error([mfilename 'Cannot handle analysis or compressed files']);
%else
    type = 'raw';
%end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% find the experiment chunk
fseek(fid,softof,'bof');

% the known experiment types (EXST is the one Gene added)
KNOWN_EXPERIMENT_CHUNKS = {'COST','EXST'};

expt = []; cof = 0;
for n=1:length(KNOWN_EXPERIMENT_CHUNKS)
    if isempty(expt) 
        fprintf('%s: looking for chunk %s\n',mfilename,KNOWN_EXPERIMENT_CHUNKS{n});
        [expt,cof] = findChunkInFile(KNOWN_EXPERIMENT_CHUNKS{n},fid); 
    end
end
assert('isempty(expt)',1,[mfilename ': cannot find experiment chunk in file ' fopen(fid)],onError); 

fprintf('%s: Found %s experiment chunk\n',mfilename,expt.ID);

% read the experiment chunk
[cost,cof] = readChunk('COST_CHUNK',fid);

[data,dataPos(1)] = readChunk('DATA_CHUNK',fid);
fprintf('%s: %i bytes of data in file %s\n',mfilename,data.Size,soft.ThisFilename);

% go through the linked list of file names making sure all files are there
nFramesInFile(1) = soft.NFramesThisFile;
fileNames{1} = soft.ThisFilename;
nFilesTotal = 1;

filePath = [fileparts(fromFileName) '/'];
fprintf('%s: File %s has %i frames\n',mfilename,[filePath soft.ThisFilename],nFramesInFile(1));

if exist([filePath soft.NextFilename],'file') == 2
    fprintf('%s: This timeseries is stored in multiple files...\n',mfilename);
    
    % opening the next file
    soft2 = soft;
    while exist([filePath soft2.NextFilename],'file') == 2            
        fprintf('%s: File %s has...',mfilename,[filePath soft2.NextFilename]);
%         keyboard;
        fid2 = fopen([filePath soft2.NextFilename],'r');
        [chunk2 cof2] = readChunk('DATA_CHUNK',fid2,1);
        if ~strcmp(chunk2.ID,'ISOI')
            fclose(fid2);
            resp = questdlg([mfilename ': cannot find ISOI chunk in file ' soft2.NextFilename 'proceed anyway?'],'File Error','Yes','No','Yes');
            switch resp
            case 'No'
                onError; return;
            end
        end
	
        [soft2,softof2] = findChunkInFile('SOFT',fid2);
        if isempty(soft2)
            fclose(fid2);
            resp = questdlg([mfilename ': cannot find SOFT chunk in file ' soft2.NextFilename 'proceed anyway?'],'File Error','Yes','No','Yes');
            switch resp
            case 'No'
                onError; return;
            end
        end
        
        soft2 = readChunk('SOFT_CHUNK',fid2);
        
        % find the experiment chunk
        fseek(fid2,softof2,'bof');
              
        [expt2,cof2] = findChunkInFile(expt.ID,fid2); 
        
        if isempty(expt2)
            fclose(fid2)
            resp = questdlg([mfilename ': cannot find ' expt.ID ' chunk in file ' soft2.NextFileName 'proceed anyway?'],'File Error','Yes','No','Yes');
            switch resp
            case 'No'
                onError; return;
            end
        end 
        
        % read the experiment chunk
        [cost2,cof2] = readChunk('COST_CHUNK',fid2);
        
        nFilesTotal = nFilesTotal+1;
        [data2,dataPos(nFilesTotal)] = readChunk('DATA_CHUNK',fid2);
        nFramesInFile(nFilesTotal) = soft2.NFramesThisFile;
        fileNames{nFilesTotal} = soft2.ThisFilename;
        
        fprintf(' %i frames\n',nFramesInFile(nFilesTotal));
        fprintf('%s: %i bytes of data in file %s\n',mfilename,data2.Size,soft2.ThisFilename);
                
        fclose(fid2);
    end
end

nFramesTotal = sum(nFramesInFile);

if nFramesTotal>params.max_frames
    fprintf('%s: too many frames (%i) in timeseries (max = %i)\n',mfilename,soft.NFramesThisFile,params.max_frames);
    return;
elseif nFramesTotal<params.min_frames
    fprintf('%s: too few frames (%i) in timeseries (min = %i)\n',mfilename,soft.NFramesThisFile,params.min_frames);
    return;
end

dataType = soft.SizeOfDataType;
switch dataType
case 1
    dataTypeString = 'uint8';
case 2
    dataTypeString = 'uint16';
case 3
    dataTypeString = 'uint32';
case 4
    dataTypeString = 'uint64';
otherwise
    assert('1',1,[mfilename ': unhandled data size of ' num2str(soft.SizeOfDataType^2*4) ' bytes'],onError);
end
fprintf('%s: data type is %s\n',mfilename,dataTypeString);

fprintf('%s: Timeseries Tag is %s with %i frames\n',mfilename,tag,nFramesTotal);


% figure out how large the file size is and how many frames can be read into memory at the same time
% I will currently set the limit to 50K of data per images matrix
% The convention will be to have the following names:
%   images      1-50M of data
%   images1   51-100M of data
%   images2  101-150M of data
%   etc...
dataInThisSeries = ((soft.SizeOfDataType^2*4/8) * XYSize * nFramesTotal)/2^20; % in MB
singleFrameSize = ((soft.SizeOfDataType^2*4/8) * XYSize)/2^20; % in MB
fprintf('%s: This timeseries contains %1.2f MB of data and each frame is %1.3f MB\n',mfilename,dataInThisSeries,singleFrameSize);

nFramesPerChunk = floor(params.chunk_size/singleFrameSize);

% create names of further images chunks (up to 100)
imgVarNames = {};
for n = 1:100
    imgVarNames{n} = ['images' num2str(n)];
end

curFrame = 0;
prevFile = 1;
curFile = 1;

frameSynch = zeros(4,nFramesTotal,2);

nFramesLEDTotal = [0 0];

maxValue = soft.SpatialBinningX*soft.SpatialBinningY*soft.TemporalBinning*2^12;
frameMean = zeros(nFramesTotal,2);
frameArrivalTime = zeros(nFramesTotal,2);

curFileFrame = [1 1];
curChunkFrame = [1 1];
curChunk = [1 1];
curOutFileSynch = [-1 -1];
curOutFile = [1 1];
curLEDFrame = [0 0];

LED_trace = zeros(1,nFramesTotal);
averageFrame = 0;

[outPath outRoot] = fileparts(toFileName);
[outExpt tmp] = strtok(outRoot,'_');
outID = strtok(tmp,'_');

curOutFileName = cell(1,2);

switch convertTo
case 0 % mat format
    mat_version = 'continuous';
    fileSequence = struct('name','','first_frame',-1,'last_frame',-1);
    
    h_fig(1) = figure('doublebuffer','on');
    h_fig(2) = figure('doublebuffer','on');
    
    h_wait = waitbar(0,'Total Progress...');
    for curFrame = 1:nFramesTotal % for all the frames
        
        % file management - switch between val files
        curFile = min(find(cumsum(nFramesInFile)>=curFrame));    
        
        % move to the next file
        if curFile>prevFile
            if prevFile>1; fclose(fid); end;
            % open the next file
            fid = fopen([params.source_path fileNames{curFile}]);
            % seek to the position of data in the next file
            fseek(fid,dataPos(curFile),'bof');
            prevFile = curFile;
        end
    
        curFrameChunk = readChunk('FRAM_CHUNK',fid);
        curCostChunk = readChunk('FRAM_COST_CHUNK',fid);
        curImage = fread(fid,XYSize,dataTypeString);
        
	% determine the led
	LED = curCostChunk.SynchChannel;
	LED = LED(1,1)+1;
	LED_trace(curFrame) = LED;
	
	curLEDFrame(LED) = curLEDFrame(LED) + 1;

	if curFrame==1	    
            frames = struct('frame',[],'frame_cost',[],'image',[]);
	    images = zeros(XYSize,nFramesPerChunk);	  
	    
	    frames_1 = struct('frame',[],'frame_cost',[],'image',[]);
	    images_1 = zeros(XYSize,nFramesPerChunk);
	    
	    isOdd = mod(nFramesTotal,2);   
	    
	    nFramesLEDTotal(:) = floor((nFramesTotal+isOdd)/4);
	    nFramesLEDTotal(LED) = ceil((nFramesTotal+isOdd)/4);

	    first_LED = LED;	    
	    
	end
	
	% do separately for each led
	if curFrame > 1
	  if LED~=LED_trace(curFrame-1)
	    frames_temp = frames;
	    images_temp = images;
	    frames = frames_1;
	    images = images_1;
	    frames_1 = frames_temp;
	    images_1 = images_temp;
	    clear images_temp frames_temp;
	  end
	end
	
	frameSynch(:,curLEDFrame(LED),LED) = curCostChunk.SynchChannel;

	if curFrame > 1
	  if LED_trace(curFrame)==LED_trace(curFrame-1)
	    curLEDFrame(LED) = curLEDFrame(LED)-1;
	    curChunkFrame(LED) = curChunkFrame(LED)-1;
	    curFileFrame(LED) = curFileFrame(LED)-1;
	    averageFrame = 1;
	  else
 	    averageFrame = 0;
	  end
	end

	if LED~=first_LED
	  frameSynch(4,curLEDFrame(LED),LED) = frameSynch(4,curLEDFrame(first_LED),first_LED);
	end
	
	frameMean(curLEDFrame(LED),LED) = mean(curImage);
	frameArrivalTime(curLEDFrame(LED),LED) = curFrameChunk.TimeArrivalUsec/1000; % convert to msec
	
	if curLEDFrame(LED) == 1
	  frameMean(:,LED) = frameMean(1,LED);
	  frameSynch(1,:,LED) = frameSynch(1,1,LED); % now is the led number 
	  frameSynch(2,:,LED) = frameSynch(2,1,LED);
	  frameSynch(3,:,LED) = frameSynch(3,1,LED);
	  frameSynch(4,:,LED) = frameSynch(4,1,LED);
            
	  figure(h_fig(LED));
	  subplot(5,1,1); plot(frameSynch(1,:,LED),'r');
	  subplot(5,1,2); plot(frameSynch(2,:,LED),'b');
	  subplot(5,1,3); plot(frameSynch(3,:,LED),'k');
	  subplot(5,1,4); plot(frameSynch(4,:,LED),'m');
	  subplot(5,1,5); plot(frameMean(:,LED),'k');
	  if frameMean(curLEDFrame(LED),LED)==maxValue
	    plot(curLEDFrame(LED),frameMean(1,LED),'ro');
	  end
	end
        
	% if this is the first frame then init variables
	if curLEDFrame(LED) == 1
            
	  curOutFileSynch(LED) = frameSynch(4,curLEDFrame(LED),LED);
	  curOutFileName{LED} = sprintf('%s/%s_%i_%s_%05i.mat',outPath,outExpt,LED,outID,curOutFileSynch(LED));
	  fileSequence(1,LED).name = curOutFileName{LED};
	  fileSequence(1,LED).first_frame = 1;
            
	  % if this is the end of the last trial then save the old
          % trial's data
	  % only check on led 1 so as to have even number of frames 
	elseif curOutFileSynch(LED)~=frameSynch(4,curLEDFrame(LED),LED) 
	  
	  % update plot at end of each trial
	  figure(h_fig(LED));
	  subplot(5,1,1); plot(frameSynch(1,:,LED),'r');
	  subplot(5,1,2); plot(frameSynch(2,:,LED),'b');
	  subplot(5,1,3); plot(frameSynch(3,:,LED),'k');
	  subplot(5,1,4); plot(frameSynch(4,:,LED),'m');
	  subplot(5,1,5); plot(frameMean(:,LED),'k');
	  if frameMean(curLEDFrame(LED),LED)==maxValue
	    plot(curLEDFrame(LED),frameMean(1,LED),'ro');
	  end
	  
	  % write the last chunk of the previous trial to file if there
	  % are any frames in it
	  if curChunkFrame(LED)>1 % if it is 1 then some chunk was just written
	    if curChunk(LED)==1
	      first_image = images(:,1); % trunkcate images to just be the collected data
	      images = images(:,1:curChunkFrame(LED)-1);
	      frames = frames(1:curFileFrame(LED)-1);
	      %keyboard;
	      fprintf('%s: Writing chunk 1 with %i frames to %s... \n',mfilename,curChunkFrame(LED)-1,curOutFileName{LED});
	      if ~exist(curOutFileName{LED},'file')
		save(curOutFileName{LED},'type','soft','cost','frames','images','first_image','mat_version');
	      else
		fprintf('%s: File %s already exists... skipping\n',mfilename,curOutFileName{LED});
	      end
	    else

      	      images = images(:,1:curChunkFrame(LED)-1); % truncate images to just be the collected data
	      frames = frames(1:curFileFrame(LED)-1);
	      eval([imgVarNames{curChunk(LED)-1} ' = images;']);
	      fprintf('%s: Writing chunk %i with %i frames to %s... \n',mfilename,curChunk(LED),curChunkFrame(LED)-1,curOutFileName{LED});
	      if ~exist(curOutFileName{LED},'file')
		save(curOutFileName{LED},imgVarNames{curChunk(LED)-1},'frames','-append');
	      else
		temp = who('-file',curOutFileName{LED});
		if isempty(find(strcmp(temp,imgVarNames{curChunk(LED)-1})))
		  save(curOutFileName{LED},imgVarNames{curChunk(LED)-1},'frames','-append');
		else
		  fprintf('%s: File %s already exists... skipping\n',mfilename,curOutFileName{LED});
		end
	      end
	      clear(imgVarNames{curChunk(LED)-1});
	    end
	  end
	  images = zeros(XYSize,nFramesPerChunk);
	  
	  fprintf('%s: Finished file %s\n',mfilename,curOutFileName{LED});
	  
	  fileSequence(curOutFile(LED),LED).last_frame = curLEDFrame(LED)-1;
	  curOutFile(LED) = curOutFile(LED) + 1;
	  curOutFileSynch(LED) = frameSynch(4,curLEDFrame(LED),LED);
	  curOutFileName{LED} = sprintf('%s/%s_%i_%s_%05i.mat',outPath,outExpt,LED,outID,curOutFileSynch(LED));
	  fileSequence(curOutFile(LED),LED).name = curOutFileName{LED};
	  fileSequence(curOutFile(LED),LED).first_frame = curLEDFrame(LED);
	  curFileFrame(LED) = 1;
	  curChunkFrame(LED) = 1;
	  curChunk(LED) = 1;
	  
	end
        
	
	% add the frame information onto the list
	frames(curFileFrame(LED)).frame = curFrameChunk;
	frames(curFileFrame(LED)).frame_cost = curCostChunk;
	frames(curFileFrame(LED)).image = curLEDFrame(LED);
	if averageFrame
	  images(:,curChunkFrame(LED)) = (images(:,curChunkFrame(LED))+curImage)/2;
	else
	  images(:,curChunkFrame(LED)) = curImage;
	end

	%keyboard;
	
	% chunk management within an experiment file - write full chunks to disk
	if curChunkFrame(LED) == nFramesPerChunk
	  % start a new chunk
	  if curChunk(LED)==1
	    first_image = images(:,1);
	    fprintf('%s: Writing chunk 1 with %i frames to %s... \n',mfilename,curChunkFrame(LED),curOutFileName{LED});
	    if ~exist(curOutFileName{LED},'file')
	      save(curOutFileName{LED},'type','soft','cost','frames','images','first_image','mat_version');
	    else
	      fprintf('%s: File %s already exists... skipping\n',mfilename,curOutFileName{LED});
	      end
	  else
	    eval([imgVarNames{curChunk(LED)-1} ' = images;']);
	    fprintf('%s: Writing chunk %i with %i frames to %s... \n',mfilename,curChunk(LED),curChunkFrame(LED),curOutFileName{LED});
	    if ~exist(curOutFileName{LED},'file')
	      save(curOutFileName{LED},imgVarNames{curChunk(LED)-1},'frames','-append');
	    else
	      temp = who('-file',curOutFileName{LED});
	      if isempty(find(strcmp(temp,imgVarNames{curChunk(LED)-1})))
		save(curOutFileName{LED},imgVarNames{curChunk(LED)-1},'frames','-append');
	      else
		fprintf('%s: File %s already exists... skipping\n',mfilename,curOutFileName{LED});
	      end
	    end
	    clear(imgVarNames{curChunk(LED)-1});
	  end
	  images(:) = 0;
	  curChunk(LED) = curChunk(LED) + 1;
	  curChunkFrame(LED) = 0;
	end
	
	if curLEDFrame(LED)==nFramesLEDTotal(LED) % if this is the last frame then finish file
	  if curChunk(LED) == 1
	    first_image = images(:,1);
	    images = images(:,1:curChunkFrame(LED)); % truncate images to just be the collected data
	    frames = frames(1:curFileFrame(LED));
	    fprintf('%s: Writing chunk 1 with %i frames to %s... \n',mfilename,curChunkFrame(LED),curOutFileName{LED});
	    if ~exist(curOutFileName{LED},'file')
	      save(curOutFileName{LED},'type','soft','cost','frames','images','first_image','mat_version');
	    else
	      fprintf('%s: File %s already exists... skipping\n',mfilename,curOutFileName{LED});
	    end
	  else
	    images = images(:,1:curChunkFrame(LED)); % truncate images to just be the collected data
	    frames = frames(1:curChunkFrame(LED));
	    eval([imgVarNames{curChunk(LED)-1} ' = images;']);
	    fprintf('%s: Writing chunk %i with %i frames to %s... \n',mfilename,curChunk(LED),curChunkFrame(LED),curOutFileName{LED});
	    if ~exist(curOutFileName{LED},'file')
	      save(curOutFileName{LED},imgVarNames{curChunk(LED)-1},'frames','-append');
	    else
	      temp = who('-file',curOutFileName{LED});
	      if isempty(find(strcmp(temp,imgVarNames{curChunk(LED)-1})))
		save(curOutFileName{LED},imgVarNames{curChunk(LED)-1},'frames','-append');
	      else
		fprintf('%s: File %s already exists... skipping\n',mfilename,curOutFileName{LED});
	      end
	    end
	    clear(imgVarNames{curChunk(LED)-1});
	  end
	end
	
	curFileFrame(LED) = curFileFrame(LED) + 1;
	curChunkFrame(LED) = curChunkFrame(LED) + 1;

        waitbar(curFrame/nFramesTotal,h_wait);
    end
    close(h_wait); close(h_fig);
    
    frameSynch2 = frameSynch;
    frameMean2 = frameMean;
    fileSequence2 = fileSequence;
    frameArrivalTime2 = frameArrivalTime;
    for LED = 1:2
      
      fileSequence2(end,LED).last_frame = nFramesLEDTotal(LED);
      synchOutFile{LED} = sprintf('%s/%s_%i_%s_%05i_SYNCH.mat',outPath,outExpt,LED,outID,frameSynch(4,1));
      fprintf('%s: Writing frame synch information to file %s\n',mfilename,synchOutFile{LED});      

      frameSynch = frameSynch2(:,1:nFramesLEDTotal(LED),LED);
      frameMean = frameMean2(1:nFramesLEDTotal(LED),LED)';
      fileSequence = fileSequence2(:,LED);
      frameArrivalTime = frameArrivalTime2(1:nFramesLEDTotal(LED),LED)';

      % remove path from saved filename
      for f=1:length(fileSequence)
	[pt,nm,ex] = fileparts(fileSequence(f).name);
	fileSequence(f).name = [nm ex];
      end
      
      save(synchOutFile{LED},'frameSynch','frameMean','fileSequence','frameArrivalTime');
    end
    
    fprintf('Done\n');
    
case 1 % ani format
    warning([mfilename ': Saving to ANI format loses synch information']);
    fprintf('%s: Writing %s... ',mfilename,toFileName);
    outFid = fopen(toFileName,'w+');
    assert('fid==-1',1,[mfilename ': Could not open file : ' toFileName],onFileError);
    count = 0;
    count = count + fwrite(outFid,dataType,'int16');    % data type
    count = count + fwrite(outFid,soft.XSize,'int16');  % x size
    count = count + fwrite(outFid,soft.YSize,'int16');  % y size
    assert('count==3',0,[mfilename ': error writing file'],onFileError);
    
    h_wait = waitbar(0,'Copying Frames...');
    for n=1:nFramesTotal
        curFile = min(find(cumsum(nFramesInFile)>n));
        
        % move to the next file
        if curFile>prevFile
            if prevFile>1; fclose(fid); end;
            % open the next file
            fid = fopen([params.source_path fileNames(curFile)]);
            % seek to the position of data in the next file
            fseek(fid,dataPos(curFile));
            prevFile = curFile;
        end
        
        [fram,cof] = readChunk('FRAM_CHUNK',fid);
        [fram_cost,cof] = readChunk('FRAM_COST_CHUNK',fid);
        count = fwrite(outFid,fread(fid,XYSize,dataTypeString),dataTypeString);
        assert('count==XYSize',0,[mfilename ': error writing file'],[onFileError 'close(h_wait);']);
        waitbar(n/soft.NFramesThisFile,h_wait);
    end
   
    close(h_wait);
    fprintf('Done\n');
    
    fclose(outFid);    
end

function convertImgDataFromMatToAni(fid)


function convertImgDataFromAniToMat(fid)
