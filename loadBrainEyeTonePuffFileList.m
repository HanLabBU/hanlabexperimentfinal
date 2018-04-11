
d = dir('FileList*Brain*');
load(d(1).name)
for k=1:numel(DataSet_FileList)
   tmp(k) = load(DataSet_FileList{k});
end
datafilenamecell = fields(tmp);
datafilename = datafilenamecell{1};
brainfiles = cat(2, tmp.(datafilename))';
brainfiles = brainfiles([brainfiles.numFrames]>=1);
braininfo = getInfo(brainfiles, 'cat');
% [braindata,braininfo] = getData(brainfiles);
clear d tmp datafilenamecell datafilename k DataSet_FileList


d = dir('FileList*Eye*');
load(d(1).name)
for k=1:numel(DataSet_FileList)
   tmp(k) = load(DataSet_FileList{k});
end
datafilenamecell = fields(tmp);
datafilename = datafilenamecell{1};
eyefiles = cat(2, tmp.(datafilename))';
eyefiles = eyefiles([eyefiles.numFrames]>=1);
eyeinfo = getInfo(eyefiles, 'cat');
% [eyedata,eyeinfo] = getData(eyefiles);
clear d tmp datafilenamecell datafilename k DataSet_FileList


d = dir('FileList*TonePuff*');
load(d(1).name)
for k=1:numel(DataSet_FileList)
   tmp(k) = load(DataSet_FileList{k});
end
datafilenamecell = fields(tmp);
datafilename = datafilenamecell{1};
tpfiles = cat(2, tmp.(datafilename))';
tpfiles = tpfiles([tpfiles.numFrames]>=1);
tpinfo = getInfo(tpfiles, 'cat');
% [tpdata,tpinfo] = getData(tpfiles);
clear d tmp datafilenamecell datafilename k DataSet_FileList
