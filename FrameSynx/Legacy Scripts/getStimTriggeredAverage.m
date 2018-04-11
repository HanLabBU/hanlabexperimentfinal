%
% GETSTIMTRIGGEREDAVERAGE: Get mean data triggered on triggers within a
% window 
%
% AVG = GETSTIMTRIGGEREDAVERAGE(DATA,TRIGGERS,WINDOW) 
%   Returns the average segment of data with length WINDOW, triggered on
%   data points specified in TRIGGERS
%
% [AVG,ERR] = GETSTIMTRIGGEREDAVERAGE(DATA,TRIGGERS,WINDOW)
%   Also returns the error in ERR as STD
%
% [AVG,ERR,ALL] = GETSTIMTRIGGEREDAVERAGE(DATA,TRIGGERS,WINDOW)
%   Also returns all the triggered sequences as a matrix ALL
%
function [avg,err,all] = getStimTriggeredAverage(data,triggers,window)

[Np,Nt] = size(data);

nTriggers = length(triggers);
avg = zeros(Np,window);
if nargout>1
    err = zeros(Np,window);
end

tooEarly = triggers<1;
tooLate = (triggers+window-1)>size(data,2);
fprintf('%s: excluding %i early and %i late triggers\n',mfilename,sum(tooEarly),sum(tooLate));
triggers = triggers(~tooEarly & ~tooLate);
nTriggers = length(triggers);

if nargout>2
    all = zeros(nTriggers,Np,window);
end

nanTriggers = sum(isnan(triggers));

for t = 1:nTriggers
    
    if ~isnan(triggers(t))
        
        %     plot(conv(data(triggers(t)+1:triggers(t)+window)-mean(data(triggers(t)+1:triggers(t)+window)),gausswin(3))); hold on;
        %     plot(data(triggers(t)+1:triggers(t)+window)-mean(data(triggers(t)+1:triggers(t)+window))); hold on;
        avg = avg+data(:,triggers(t):triggers(t)+window-1);
        if nargout>1
            err = err+(data(:,triggers(t):triggers(t)+window-1)-repmat(mean(data(:,triggers(t):triggers(t)+window-1),2),[1,window])).^2;
        end

        if nargout>2
            all(t,:,:) = data(:,triggers(t):triggers(t)+window-1);
        end
    else
        all(t,:,:) = nan(Np,window);
    end
end

avg = avg/(nTriggers-nanTriggers);

if nargout>1
    err = sqrt(err/(nTriggers-nanTriggers-1));
end

if nargout>2
    all = squeeze(all);
end