function sys = runTonePuffWithCam()

warning('off', 'imaq:dcam:nocamerasfound');
for k=1:10
   imaqreset
   if any(strcmp('pointgrey',Camera.availableAdaptors))
	  break
   end
end

sys.tonepuff = TonePuffSystem;
setup(sys.tonepuff)
sys.braincam = BrainCamSystem;
sys.braincam.experimentSyncObj = sys.tonepuff;
sys.braincam.trialSyncObj = sys.tonepuff;
sys.braincam.cameraObj.exposureTime = 1/sys.tonepuff.frameClkFrequency

sys.eyecam = EyeCamSystem;
sys.eyecam.experimentSyncObj = sys.tonepuff;
sys.eyecam.trialSyncObj = sys.tonepuff;
% sys.eyecam.cameraObj.exposureTime = 1/sys.tonepuff.frameClkFrequency;
% sys.eyecam.cameraObj.videoSrcObj.FrameRatePercentage = 16
% start(sys.braincam)
% start(sys.tonepuff)