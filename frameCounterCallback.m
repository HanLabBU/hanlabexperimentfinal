function frameCounterCallback(src,evnt)
global FRAMECOUNT
global FLASH

if isempty(FRAMECOUNT)
   FRAMECOUNT = 1;
elseif FRAMECOUNT == 50
   fprinf('********FLASH**********\n')
   FLASH.sendPulse(pulseOnTime, nPulses, pulseOnVal)
else
   FRAMECOUNT = FRAMECOUNT + 1;
end
fprintf(' Frame-Counter: %i\n' FRAMECOUNT)

