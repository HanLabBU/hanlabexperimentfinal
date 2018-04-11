function convertVal2MatContinuous(filenames)

%converts all val files in current directory to mat files
  warning off;

nFiles = length(filenames);
index = filterValFiles(filenames);

params = struct('max_frames',Inf,'min_frames',0,'dest_path','../Mat');

valFiles = filenames(index);

prefixes = vertcat(valFiles.name);
prefixes = prefixes(:,[1:4]);
expts = unique(prefixes,'rows');

for n = 1:size(expts,1)
  firstFile(n) = valFiles(min(strmatch(expts(n,:),prefixes)));
end

for n = 1:size(firstFile(n))
  convertImgDataContinous(firstFile(n).name,'val','mat',params)
end
