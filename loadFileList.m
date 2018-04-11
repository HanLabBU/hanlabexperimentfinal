function datafiles = loadFileList

filelist = uigetfile();
load(filelist)
for k=1:numel(DataSet_FileList)
   tmp(k) = load(DataSet_FileList{k});
end
datafilenamecell = fields(tmp);
datafilename = datafilenamecell{1};
datafiles = cat(2, tmp.(datafilename))';
