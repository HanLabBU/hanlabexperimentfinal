function convertVal2MatContinuousRedGreen(filenames)

%converts all val files in current directory to mat files
  warning off;

nFiles = length(filenames);
index = filterValFiles(filenames);

params = struct('max_frames',Inf,'min_frames',0,'dest_path','../Mat','force_alternation',1);

valFiles = filenames(index);

prefixes = vertcat(valFiles.name);
prefixes = prefixes(:,[1:4]);
expts = unique(prefixes,'rows');

for n = 1:size(expts,1)
  firstFile(n) = valFiles(min(strmatch(expts(n,:),prefixes)));
end

firstFile = {firstFile.name};

%keyboard;

for n = 1:length(firstFile)
  convertImgDataContinuousRG(firstFile{n},'val','mat',params)
end
