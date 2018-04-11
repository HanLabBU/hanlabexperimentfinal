imaqreset
global CURRENT_EXPERIMENT_PATH

ss = SystemSynchronizer('saveRoot','F:\Data\TonePuff');
braincamObj = CameraSystem('cameraClass','HamamatsuCamera', 'systemName','braincam');
eyecamObj = CameraSystem('cameraClass','PtGreyCamera', 'systemName','eyecam');
ss.register(braincamObj)
ss.register(eyecamObj)





