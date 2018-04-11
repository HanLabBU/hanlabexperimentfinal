function plotData(src,event)
persistent hFig
persistent hLine
if isempty(hFig) || ~ishghandle(hFig)
	hFig = handle(figure);
end
if isempty(hLine) || ~ishghandle(hLine)
	hLine = handle(line('XData',event.TimeStamps,'YData',event.Data));
	hLine.LineWidth = 2;
	return
end
hAx = hLine.Parent;
hLine.XData = [hLine.XData(:) ;  event.TimeStamps(:)];
hLine.YData = [hLine.YData(:) ; event.Data(:)];
end