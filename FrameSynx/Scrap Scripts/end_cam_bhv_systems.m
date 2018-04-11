try
		delete(camsystem)
		delete(bhvsystem)
catch me
		disp('no cam or bhv')
end
clear all
close all
imaqreset
instrreset
fclose('all');