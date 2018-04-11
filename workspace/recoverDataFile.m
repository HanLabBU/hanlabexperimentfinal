function datafileObj = recoverDataFile(protoObj)
%
% if nargin < 1
%    [protofileName, protofileDir] = uigetfile('*.mat','Select file with prototypes')
% end

fromProtoObj = {'headerFormat','infoFields', 'infoFormat', 'dataSize', 'dataType', 'numChannels'};

[tphName, tphDir] = uigetfile('*.fhf','Select a Header File to Recover','MultiSelect','on');
if ischar(tphName)
   tphName = {tphName};
end
firstFrame = 1;
trialNumber = 0;
dataFileClass = class(protoObj);
dataFileConstructor = sprintf('%s(propStruct);',dataFileClass);
dataFileObj = eval(sprintf('%s.empty(numel(tphName),0)',dataFileClass));
for kFile = 1:numel(tphName)
   % FILL PROPERTIES FROM HEADER FILE
   fname = fullfile(tphDir,tphName{kFile});
   headerMap = memmapfile(fname,...
	  'format',protoObj.headerFormat,...
	  'writable',true);
   propStruct = headerMap.Data;
   props = fields(propStruct);
   % CONVERT UINT16 BACK TO CHAR
   for kProp = 1:numel(props)
	  prop = props{kProp};
	  if isa(propStruct.(prop), 'uint16')
		 strProp = char(propStruct.(prop));
		 strLength = find(~isstrprop(strProp, 'wspace'), 1, 'last');
		 propStruct.(prop) = strProp(1:strLength);
	  end
   end
   % FILL PROPERTIES FROM PROTOTYPE OBJECT
   for kProtoProp = 1:numel(fromProtoObj)
	  prop = fromProtoObj{kProtoProp};
	  propStruct.(prop) = protoObj.(prop);
   end
   % FILL PROPERTIES INFERRED FROM SIZE OF BINARY DATA-FILE
   protoFrame = zeros(propStruct.dataSize, propStruct.dataType);
   m = whos('protoFrame'); %# protoFrame
   bytesPerFrame = m.bytes;
   [fid, msg] = fopen(fullfile(propStruct.rootPath,'FrameSyncFiles', propStruct.dataFileName), 'rb');
   if fid < 1
	  keyboard
   end
   fseek(fid,0, 'eof');   
   nBytes = ftell(fid);
   fclose(fid);
   propStruct.numFrames = nBytes / bytesPerFrame;
   propStruct.firstFrame = firstFrame;
   propStruct.lastFrame = firstFrame + propStruct.numFrames - 1;
   firstFrame = propStruct.lastFrame + 1;
   % OTHER
   propStruct.recovery = true;
   propStruct.filesOpen = false;
   propStruct.filesClosed = true;   
   if ~logical(propStruct.trialNumber)
	  propStruct.trialNumber = trialNumber;
	  trialNumber = trialNumber + 1;
   end
   datafileObj(kFile) = eval(dataFileConstructor);
end