experimentObj = r111;
h = figure;
ratCheck = false(length(experimentObj.trialSet),1);
for n = 1:length(experimentObj.trialSet)
		figure(h);
		imaqmontage(experimentObj.trialSet(n).video);
		output = questdlg('Is the rat there?','Rat-Check!','Yes');
		if strcmp(output,'Yes')
				ratCheck(n) = true;
		else
				ratCheck(n) = false;
		end
end
