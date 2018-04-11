
[data info] = getData(vrffiles);
w = exper.worlds{1};
w.draw3D
h = handle(gca);
h.DataAspectRatio = [1 1 1];
h.ALimMode = 'manual';
set(h.Children,'AlphaDataMapping','scaled')
h.ALim = [.1 2];
hold on
hquiv = handle(quiver(info.Xpos(200:end), info.Ypos(200:end),...
	squeeze(data(5,1,1,200:end)), squeeze(data(5,2,1,200:end))));