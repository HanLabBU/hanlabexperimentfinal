function tpts = showTonePuffTimeseries(info)

fs.tonepuff = 100000;
tone.delay = 0;
tone.duration = .35;
puff.delay = .25;
puff.duration = .1; 
startDelay = 10;
% FIND A TONEPUFF FILE IF THE INFO STRUCTURE ISN'T PROVIDED AS INPUT
if nargin < 1
   d = dir('*_TonePuffSystem*.mat');
   if isempty(d)
	  [fname,fdir] = uigetfile('Choose a TonePuffSystem Behavioral File');
	  fpath = fullfile(fdir, fname);
   else
	  fpath = fullfile(pwd,d.name);
   end
   fstruct = load(fpath);
   tpfile = fstruct.(char(fields(fstruct)));
   info = getInfo(tpfile, 'cat');
end
% INTERPRET/APPROXIMATE FRAMES WHEN EACH STIMULUS IS ON (RELATIVE TO TRIAL START)
N = numel(info.timeStamp);
fs.cam = 1/mean(diff(info.timeStamp));
tone.n = fix(max(info.toneSamplesQueued) * fs.cam/fs.tonepuff);
tone.on = NaN(N,1);
tone.frames = round(tone.delay*fs.cam) : round((tone.delay+tone.duration)*fs.cam);
puff.n = fix(max(info.puffSamplesQueued) * fs.cam/fs.tonepuff);
puff.on = NaN(N,1);
puff.frames = round(puff.delay*fs.cam) : round((puff.delay+puff.duration)*fs.cam);
% FILL FRAME-SYNCHRONIZED SIGNALS
trialOnsetFrame = find(info.firstFrame == 1);
for k=1:numel(trialOnsetFrame)
   m = trialOnsetFrame(k);
   tone.on( m + tone.frames) = .45;
   puff.on( m + puff.frames) = .55;   
end

plot(info.timeStamp, tone.on,'LineWidth',10, 'color', [0 .5 0 .5], 'marker', '>', 'markerfacecolor', 'flat');
hold on
plot(info.timeStamp, puff.on,'LineWidth',5, 'color', [.9 0 0 .5], 'marker', 'o', 'markerfacecolor', 'flat');


tpts.info = info;
tpts.tone = tone;
tpts.puff = puff;