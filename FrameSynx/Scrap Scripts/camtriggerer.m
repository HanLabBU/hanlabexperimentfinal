framerate = 7.5;
start(obj)
for ntrials = 1:13
		for nframes = 1:15;
				syncExternal(obj)
				pause(1/framerate)
				
		end
		obj.saveDataFile;
end
stop(obj)