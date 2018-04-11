clear all
clc
load samptrial.mat
vid = t.video;
testcond = {'low-level disk','memory-mapped','RAM'};

mem = memory;
nrep = 1000;
tic
for n=1:nrep
		tr = Trial(1);
		tr.defaultSaveMethod = 'todisk';
		tr.video = vid;
end
maketime(1) = toc;
% mem(2) = memory;
% memused(1) = mem(2).MemUsedMATLAB- mem(1).MemUsedMATLAB;
tic
for n = 1:nrep
		a = tr.video;
end
loadtime(1) = toc;

pause(1)
clear tr

tic
for n=1:nrep
		tr = Trial(2);
		tr.defaultSaveMethod = 'tomemorymap';
		tr.video = vid;
end
maketime(2) = toc;
% mem(3) = memory;
% memused(2) = mem(3).MemUsedMATLAB- mem(1).MemUsedMATLAB;
tic
for n = 1:nrep
		a = tr.video;
end
loadtime(2) = toc;

pause(1)
clear tr

tic
for n=1:nrep
		tr = Trial(2);
		tr.defaultSaveMethod = 'toobject';
		tr.video = vid;
end
maketime(3) = toc;
% mem(4) = memory;
% memused(3) = mem(4).MemUsedMATLAB- mem(1).MemUsedMATLAB;
tic
for n = 1:nrep
		a = tr.video;
end
loadtime(3) = toc;

pause(1)
clear tr

% tic
% for n=1:nrep
% 		tr = Trial(2);
% 		tr.defaultSaveMethod = 'tomat';
% 		tr.video = vid;
% end
% maketime(4) = toc;
% % mem(4) = memory;
% % memused(4) = mem(4).MemUsedMATLAB- mem(1).MemUsedMATLAB;
% tic
% for n = 1:nrep
% 		a = tr.video;
% end
% loadtime(4) = toc;


stats = [maketime./max(maketime); loadtime./max(loadtime)]';
bar(stats)
legend('Make-Time','Load-Time')
xlabel('Low-Level writes               Memory-Mapped               RAM')
disp(testcond)
disp(['make: ',num2str(maketime)])
disp(['load: ',num2str(loadtime)]);











