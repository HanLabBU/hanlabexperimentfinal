function setprocesspriority
[status,result] = system('pv -ph matlab.exe');
		if status == 0
				fprintf('%s\n',result)
		else
				fprintf('Process Viewer, pv.exe, does not exist or is not in the system path: %s\n',result)
				pvlocation = which('pv.exe');
				if ~isempty(pvlocation)
						fprintf('Process Viewer can be added to the system path, or copied into Windows\\System32 from:\n%s\n\n',pvlocation)
				end
		end