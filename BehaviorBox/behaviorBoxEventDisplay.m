clear all
close all
obj = BehaviorBox2;
setup(obj);

objects2follow = {...
    'obj',...
    'obj.touchDisplayObj',...
    'obj.nidaqObj',...
    'obj.speakerObj',...
    'obj.touchDisplayObj.stimuli'}; % Rectangle objects

for n = 1:numel(objects2follow)
    o2f = eval(objects2follow{n});
    evn = events(o2f);
    for m = 1:numel(evn)-1
       addlistener(o2f,evn{m},@eventListenDisplay);
    end
end

