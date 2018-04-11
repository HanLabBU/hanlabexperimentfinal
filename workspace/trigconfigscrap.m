
%%
% ss = SystemSynchronizer;
% obj = ss.cameraSystemObjects;

%%

obj = CameraSystem('cameraClass','DcamCamera');
cam = obj.cameraObj;
vio = cam.videoInputObj;
vss = getselectedsource(vio);

%%
vti = triggerinfo(vio);
trigfields = fields(vti);
for k = 1:numel(vti)
   trigsetting = '';
   for f = 1:numel(trigfields)
	  trigfieldname = trigfields{f};
	  trigsetting = sprintf('%s%s:%s|',trigsetting, trigfieldname,vti(k).(trigfieldname));
   end   
   trigSettingList{k,1} = trigsetting;
end
output = listdlg('PromptString','Select a Trigger Configuration:',...
            'SelectionMode','single',...
            'ListString',trigSettingList,...
			'ListSize',[700 300],...
			'Name','Camera TriggerConfig',...
			'InitialValue',4);
trigconfig = vti(output)

%%
stop(obj.cameraObj)
triggerconfig(vio,trigconfig)
obj.cameraObj.triggerConfiguration = trigconfig;
obj.cameraObj.frameSyncMode = 'auto';
start(obj)

%%
fps = cam.frameRate;
readoutTime = .011; %TODO
framePeriod = 1/fps;
exposureTime = framePeriod-readoutTime;
readoutRatio = readoutTime/framePeriod;

dev = daq.getDevices;
devName = dev(1).ID;
s = daq.createSession('ni');
s.Rate = fps;


clk = s.addCounterOutputChannel(devName,'ctr1','PulseGeneration');
clk.InitialDelay = 0;
clk.DutyCycle = readoutRatio;
s.IsContinuous = true;
clk.Frequency = fps;
s.prepare();
start(obj)


s.startBackground


