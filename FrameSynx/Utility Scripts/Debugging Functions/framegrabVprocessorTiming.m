fg = cat(1,obj.frameSyncData.AbsTime);
p = cat(1,obj.frameSyncData.HatTime);
fg = datenum(fg);
fg = fg-fg(1);
p = p-p(1);
fg = fg*60*60*24;
fgdiff = diff(fg);
pdiff = diff(p);
figure
plot([fg p])
figure
plot([fgdiff pdiff] )