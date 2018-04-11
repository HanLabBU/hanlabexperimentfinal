function [chunk,cof] = readChunk(chunkName,fid,rewind)
% reads the various defined chunks from data files generated by ContImage
% rewind specifies to rewind to the position the file was at before reading
% skip specifies not to read, but rather to skip the chunk

if nargin<3
    rewind = 0; % do not rewind file by default
end

% typedef struct FILEHEADER {
%   char		sumTag[4] ;	/* S?01, ? = F,S, M, R for expt location for sum_file Q for sumsq, R for ratio*/
%   long int	sumBytes ;	/* byte count of bytes to follow in file */
%   short int	sumXsize ;   // set from xsu.xstart,xstop
%   short int	sumYsize ;   // set from xsu.ystart,ystop
%   short int	sumNframes ; // set from xsu.sequentil
%   short int	sumNconds ;  // <-----must be set for expt to run
%   short int	sumCondNo	;	// six entries set for compatibility with IDL version
%   short int	sumOrder ;
%   float 	sumLoClip ;
%   float		sumHiClip ;
%   short int	sumLoPass ;
%   short int	sumHiPass ;   
%   long		sumLDataType ;
%   long		sumLFileType ;
%   long		sumLSizeOf ;
%   char		sumFree1[2] ;
%   short int	sumHeadersize ;
%   short int	sumNreps ;    // <-----must be set for expt to run
%   short int	sumRandomize ; 
%   short int	sumXgroup ;	/* binning done on CCD chip */ // set from xsu.xgroup	// GB: Will be removed !
%   short int	sumYgroup ;   // set from xsu.xgroup								// GB: Will be removed !
%   short int	sumGoDelay ;
%   short int	sumRatioFirstFrame ; 
%   short int	sumRatioLastFrame ;
%   short int	sumTempBinning ;   /* set if we collect in full resolution without hardware binning and want to bin */
%   long int	sumBit1 ;	/* Offset 64, bit coded, which blocks */ 
%   long int	sumBit2 ;   /* bit coded, which frames */
%   short int	sumBinning ;/* binning done on CCD */  // now this is being used for software spatila binning
%   short int	sumExposureMsec ;  // set from xsu.exposure (double)
%   float		sumMagnification ;	/* optical magnification */
%   short int	sumGain ;          // set from xsu.gain
%   short int	sumWavelength ;   
%   long		sumFrameHeaderSize ;  // used only for stream files, size of the header for each frame
%   short int	sumNframeiti ;   
%   short int	sumNframestim ;   
%   char		sumFree2[20] ;
%   long int	sumSysTime ;		// GB: Will be removed !
%   char		sumSite[4] ;        // GB: Will be removed !
%   short int	sumWinType ;        // GB: Will be removed !
%   short int	sumDay ;            // GB: Will be removed !
%   short int	sumMonth ;          // GB: Will be removed !
%   short int	sumYear ;           // GB: Will be removed !
%   char		sumDateRecorded[6] ;	/* Offset 128, ASCII */ 
%   char		sumUserName[10] ;		/* ASCII */ 
%   char		sumDateCreated[6] ;	/*  ASCII */ 
%   char		sumOrigFilename[16] ;	
% /* encoded as Sddmy.ea, Gddmy.ea, or Rddmy.ea, where S=sum, R=red, G=green
% date of experiment start: dd = day, m=month in hex, y = last digit of year, 
% e = experiment number (0, 1, 2, ...), a = run number (a, b, c, d, ... ) */
%   char		sumPrevFilename[16];
%   char		sumNextFilename[16];
%   unsigned short sumCompressedRecordSize;
%   unsigned long sumCompressedFrameSize;
%   unsigned long sumCompressedFrameNumber;
%   unsigned short sumCompressedDumbAss; //To presserve int borders
%   char	        sumFree3[46] ; // Val: used 44 bytes out of 90 in sumFree3 for PrevFilename, NextFilename, sumCompressedFrameSize, sumCompressedRecordSize and sumCompressedFrameNumber
%   char	        sumComments[256] ;		/* Offset 256 */
%   /* DATA (unlimited) starts at offset 512, or 508 bytes after tag & bytecount */
% 
% } FILEHEADER ;
%
FILEHEADER = struct(...
    'sumTag','char[4]',...
    'sumBytes','int32',...
    'sumXsize','int16',...
    'sumYsize','int16',...
    'sumNframes','int16',...
    'sumNconds','int16',...
    'sumCondNo','int16',...
    'sumOrder','int16',...
    'sumLoClip','float',...
    'sumHiClip','float',...
    'sumLoPass','int16',...
    'sumHiPass','int16',...
    'sumLDataType','long',...
    'sumLFileType','long',...
    'sumLSizeOf','long',...
    'sumFree1','char[2]',...
    'sumHeadersize','int16',...
    'sumNreps','int16',...
    'sumRandomize','int16',...
    'sumXgroup','int16',...
    'sumYgroup','int16',...
    'sumGoDelay','int16',...
    'sumRatioFirstFrame','int16',...
    'sumRatioLastFrame','int16',...
    'sumTempBinning','int16',...
    'sumBit1','int64',...
    'sumBit2','int64',...
    'sumBinning','int16',...
    'sumExposureMsec','int16',...
    'sumMagnification','float',...
    'sumGain','int16',...
    'sumWavelength','int16',...
    'sumFrameHeaderSize','long',...
    'sumNframeiti','int16',...
    'sumNframestim','int16',...
    'sumFree2','char[20]',...
    'sumSysTime','int32',...
    'sumSite','char[4]',...
    'sumWinType','int16',...
    'sumDay','int16',...
    'sumMonth','int16',...
    'sumYear','int16',...
    'sumDateRecorded','char[6]',...
    'sumUserName','char[10]',...
    'sumDateCreated','char[6]',...
    'sumOrigFilename','char[16]',...
    'sumPrevFilename','char[16]',...
    'sumNextFilename','char[16]',...
    'sumCompressedRecordSize','ushort',...
    'sumCompressedFrameSize','ulong',...
    'sumCompressedFrameNumber','ulong',...
    'sumCompressedDumbAss','ushort',...
    'sumFree3','char[46]',...
    'sumComments','char[256]');

% typedef struct ISOI_CHUNK{
%   char		ID[4];			// "ISOI"=Intrinsic Signal Optical Imaging
%   ULONG		Size;			// size of the file to follow, 0 if unknown
%   char		Tag[4];			// "COIM"=COntinuous IMaging 
% } ISOI_CHUNK;
ISOI = struct(...
    'ID','char[4]',...
    'Size','ulong',...
    'Tag','char[4]');

% typedef struct SOFT_CHUNK{
%   char		ID[4];			// "SOFT" - software chunk
%   ULONG		Size;			// size of the chunk (SOFT) to follow = 256 
%   char		Tag[4];			//01 01
%   char		DateTimeRecorded[24];	//02 07 ASCII UNIX time
%   char		UserName[16];		//03 11 ASCII 
%   char		SubjectID[16];		//04 15 ASCII 
%   char		ThisFilename[16];	//05 19 Encoded in MakeFileName
%   char		PrevFilename[16];	//06 23
%   char		NextFilename[16];	//07 27
%   ULONG		DataType;		//08 28
%   ULONG		FileType;		//09 29
%   ULONG		SizeOfDataType;		//10 30
%   ULONG		XSize;			//11 31 X size of stored frames 
%   ULONG		YSize;			//12 32 Y size of stored frames
%   ULONG		ROIXPosition;		//13 33 X coordinate of upper-left conner of ROI (before binning)
%   ULONG		ROIYPosition;		//14 34 Y coordinate of upper-left conner of ROI (before binning)
%   ULONG		ROIXSize;		//15 35 X size of ROI (before binning) 
%   ULONG		ROIYSize;		//16 36 Y size of ROI (before binning) 
%   ULONG		ROIXPositionAdjusted;	//17 37 X coordinate of upper-left conner of adjusted ROI (before binning)
%   ULONG		ROIYPositionAdjusted;	//18 38 Y coordinate of upper-left conner of adjusted ROI (before binning)
%   ULONG		ROINumber;		//19 39 Sequential ROI number. Set to 0 for main ROI
%   ULONG		TemporalBinning;	//20 40
%   ULONG		SpatialBinningX;	//21 41 X
%   ULONG		SpatialBinningY;	//22 42 Y
%   ULONG		FrameHeaderSize;	//23 43 Size of the header for each frame
%   ULONG		NFramesTotal;		//24 44 Expected number of frames 
%   ULONG		NFramesThisFile;	//25 45 Number of frames in this file
%   ULONG		WaveLength;		//26 46 Wave lenght, nanometers
%   ULONG		FilterWidth;		//27 47 Filter width, nanometers
%   char		Comments[68];		//28 64
% } SOFT_CHUNK;
SOFT_CHUNK = struct(...
    'ID','char[4]',...
    'Size','ulong',...
    'Tag','char[4]',...
    'DateTimeRecorded','char[24]',...
    'UserName','char[16]',...
    'SubjectID','char[16]',...
    'ThisFilename','char[16]',...
    'PrevFilename','char[16]',...
    'NextFilename','char[16]',...
    'DataType','ulong',...
    'FileType','ulong',...
    'SizeOfDataType','ulong',...
    'XSize','ulong',...
    'YSize','ulong',...
    'ROIXPosition','ulong',...
    'ROIYPosition','ulong',...
    'ROIXSize','ulong',...
    'ROIYSize','ulong',...
    'ROIXPositionAdjusted','ulong',...
    'ROIYPositionAdjusted','ulong',...
    'ROINumber','ulong',...
    'TemporalBinning','ulong',...
    'SpatialBinningX','ulong',...
    'SpatialBinningY','ulong',...
    'FrameHeaderSize','ulong',...
    'NFramesTotal','ulong',...
    'NFramesThisFile','ulong',...
    'WaveLength','ulong',...
    'FilterWidth','ulong',...
    'Comments','char[68]');

% typedef struct ISOI_CHUNK{
%   char		ID[4];			// "ISOI"=Intrinsic Signal Optical Imaging
%   ULONG		Size;			// size of the file to follow, 0 if unknown
% } DATA_CHUNK;
DATA_CHUNK = struct(...
    'ID','char[4]',...
    'Size','ulong');

% typedef struct COST_CHUNK{
%   char		ID[4];			// "COST" - Continuous STimulation chunk
%   ULONG		Size;			// size of the chunk (COST) to follow = 64
%   char		Tag[4];			//01 01
%   ULONG		NSynchChannels;		//02 02 Up to 4 channels. Add new values bellow if needed or use SYNC_CHUNK
%   ULONG		SynchChannelMax[4];	//03 06
%   ULONG		NStimulusChanels;	//07 07 Used if no Sync Channels present
%   ULONG		StimulusPeriod[4];	//08 11 milliseconds
%   char		Comments[20];		//12 16
% } COST_CHUNK;
COST_CHUNK = struct(...
    'ID','char[4]',...
    'Size','ulong',...
    'Tag','char[4]',...
    'NSynchChannels','ulong',...
    'SynchChannelMax','ulong[4]',...
    'NStimulusChannels','ulong',...
    'StimulusPeriod','ulong[4]',...
    'Comments','char[20]');

% typedef struct FRAMEHEADER {
%   unsigned long frameheadID; // arbitrary for future flexibility
%   unsigned long frameheadlength;  //8
%   unsigned long seqnum;  //sequence number 0,1,2,...NOT including paused frames
%   unsigned long time; //16  from the time call
%   I64 perfcount;  // from the performance counter
%   I64 perfreq; //32
%   long rep; //repetition number of this cycle
%   long trial;  // number of stim in this cycle
%   long condition;  //stimulus number
%   long frame_of_cond; //48  which frame in relation to start of stimulus
%   long frame_paused; //  binary variable, marks paused frames(=1[actually !=0])
%   long frame_type; //56  frame type, iti and stim for now
%   long seqnum_all; //sequence number 0,1,2,...INCLUDING PAUSED FRAMES
%   long synch_in; //for synchronization input signals (on port B)
%   long stim_params[48];  // extra parameters
% } FRAMEHEADER; //256 bytes total
FRAMEHEADER = struct(...
    'frameheadID','ulong',...
    'frameheadlength','ulong',...
    'seqnum','ulong',...
    'time','ulong',...
    'perfcount','int64',...
    'perfreq','int64',...
    'rep','long',...
    'trial','long',...
    'condition','long',...
    'frame_of_cond','long',...
    'frame_paused','long',...
    'frame_type','long',...
    'seqnum_all','long',...
    'synch_in','long',...
    'stim_params','long[48]');


% typedef struct FRAM_CHUNK{		// Experiment independent chunk sizeof(FRAM_CHUNK)=64
%   char		ID[4];			// "FRAM"=FRAMe header
%   ULONG		Size;			// size of the frameheader to follow sizeof(FRAM_CHUNK)-8 = 56
%   char		Tag[4];			//01 01
%   ULONG		FrameSeqNumber;	        //02 02 Frame sequential number as reported by frame grabber
%   ULONG		FrameRingNumber;	//03 03 Frame ring number as reported by frame grabber
%   ULONG		TimeArrivalUsecLo;	//04 04 Arrival time(microsec) as reported by frame grabber, low part
%   ULONG		TimeArrivalUsecHi;	//05 05 Arrival time(microsec) as reported by frame grabber, high part
%   ULONG		TimeDelayUsec;		//06 06 Difference between arrival and WaitEvent time
%   ULONG		PotentiallyBad;		//07 07 As returned by GrabWaitFrameEx
%   ULONG		Locked;			//08 08 As returned by GrabWaitFrameEx
%   ULONG		FrameSeqCount;		//09 09 Frame sequential number (should be: FrameSeqCount+1=FrameSeqNumber)
%   ULONG		CallbackResult;		//10 10 Return value of the experiment callback
%   ULONG		Free[4];		//11 14
% } FRAM_CHUNK;
FRAM_CHUNK = struct(...
    'ID','char[4]',...
    'Size','ulong',...
    'Tag','char[4]',...
    'FrameSeqNumber','ulong',...
    'FrameRingNumber','ulong',...
    'TimeArrivalUsec','uint64',...
    'TimeDelayUsec','ulong',...
    'PotentiallyBad','ulong',...
    'Locked','ulong',...
    'FrameSeqCount','ulong',...
    'CallBackResult','ulong',...
    'Free','ulong[4]');

% typedef struct FRAM_COST_CHUNK{
%   char		ID[4];			// "cost" COST experiment frame header. sizeof(FRAM_COST_CHUNK)=64
%   ULONG		Size;			// size of the frameheader and frame data to follow(sizeof(FRAM_COST_CHUNK)-8+frameSize)
%   char		Tag[4];			//01 01
%   ULONG		HeaderSize;		//02 02 size of the frameheader to follow(sizeof(FRAM_COST_CHUNK)-16)
%   ULONG		SynchChannel[4];	//02 06 Up to 4 channels. Increase the arrays size if needed or use SYNC_CHUNK
%   ULONG		SynchChannelDelay[4];	//06 10 Relative to arrival time (microseconds)
%   ULONG		Free[4];		//10 14
% } FRAM_COST_CHUNK;
FRAM_COST_CHUNK = struct(...
    'ID','char[4]',...
    'Size','ulong',...
    'Tag','char[4]',...
    'HeaderSize','ulong',...
    'SynchChannel','ulong[4]',...
    'SynchChannelDelay','ulong[4]',...
    'Free','ulong[4]');


chunkName = upper(chunkName);
if exist(chunkName);
    [chunk cof] = readStructFromFile(eval(chunkName),fid,rewind); 
else
    error([mfilename ': undefined chunk ' chunkName]);
end


function [someStruct,cof] = readStructFromFile(someStruct,fid,rewind);
% takes as input a MATLAB struct with the values in each field specifying
% the data type to read

fields = fieldnames(someStruct);

originalPos = ftell(fid);

for n=1:length(fields)
    dataType = ''; dataSize = 1;
    dataTypeAndSize = getfield(someStruct,fields{n});
    [dataType,R] = strtok(dataTypeAndSize,'[]');
    if ~isempty(R) [dataSize,R] = strtok(R,'[]'); dataSize = str2num(dataSize); end
    
    [tmp,c] = fread(fid,dataSize,dataType);
    
    if strcmp(dataType,'char')
        tmp = char(tmp)';    
    end
    
    someStruct = setfield(someStruct,fields{n},tmp);
end

% rewind the file
if rewind
    cof = ftell(fid);
    fseek(fid,originalPos-cof,'cof');
end

cof = ftell(fid);