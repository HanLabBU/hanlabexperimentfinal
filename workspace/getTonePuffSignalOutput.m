function sig = getTonePuffSignalOutput(obj)

decimateFactor = 100;

fs = obj.stimulusSampleFrequency;
tEnd = obj.trialStartTime(end);
nTrials = numel(obj.trialFirstFrame)-1;
N = fix(fs * tEnd);
t = linspace(0, tEnd, N)';

tone = zeros(N,1);
puff = zeros(N,1);

for k=1:nTrials
   m = fix(obj.trialStartTime(k)*fs);
   tone(m:(m+numel(obj.toneObj.nextSignal)-1)) = obj.toneObj.nextSignal;
   puff(m:(m+numel(obj.puffObj.nextSignal)-1)) = obj.puffObj.nextSignal;
end

if decimateFactor > 1
   sig.t = decimate(t, decimateFactor);
   sig.tone = decimate(tone, decimateFactor);
   sig.puff = decimate(puff, decimateFactor);
else
   sig.t = t;
   sig.tone = tone;
   sig.puff = puff;
end
