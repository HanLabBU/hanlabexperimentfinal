
expt.FirstFrame = [exp.trialSet.firstFrame]';
expt.LastFrame = [exp.trialSet.lastFrame]';
expt.StimOnFrame = [exp.trialSet.stimOnFrame]';
expt.StimOffFrame = [exp.trialSet.stimOffFrame]';
expt.NumFrames = [exp.trialSet.numFrames]';

gfinfo.FirstFrame = [gfi.first_frame]';
gfinfo.LastFrame = [gfi.last_frame]';
gfinfo.StimOnFrame = [gfi.FrameStimOnRel]';
gfinfo.StimOffFrame = [gfi.FrameStimOffRel]';
gfinfo.NumFrames = [gfi.NFrames]';

lf = [expt.LastFrame gfinfo.LastFrame];
ff = [expt.FirstFrame gfinfo.FirstFrame];
ffdif = ff(:,1)-ff(:,2);
lfdif = lf(:,1)-lf(:,2);

son = [expt.StimOnFrame gfinfo.StimOnFrame];
soff = [expt.StimOffFrame gfinfo.StimOffFrame];
sofshift = [expt.StimOffFrame [gfi.FrameStimShiftRel]'];
sofshift = [expt.StimOffFrame [gfi.FrameStimShiftRel]'];
sofdif = sofshift(:,1)-sofshift(:,2);
sondif = son(:,1)-son(:,2);
