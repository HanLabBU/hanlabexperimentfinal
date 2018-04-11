function keydisplayfunc(src,evnt)
if strcmp(evnt.Key,'shift')
		return
else
		disp(['Modifier: ',evnt.Modifier{:}])
		disp(['Key: ',evnt.Key])
		disp(['Character: ',evnt.Character])
		length(evnt.Modifier)
		disp('----------------------')
end
