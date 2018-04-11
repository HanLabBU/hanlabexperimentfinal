addlistener(obj.cameraObj,'CameraLogging',@eventListenDisplay);
addlistener(obj.cameraObj,'CameraStopped',@eventListenDisplay)
addlistener(obj.cameraObj,'CameraReady',@eventListenDisplay)
addlistener(obj.dataGeneratorObj,'FrameInfoAcquired',@eventListenDisplay)
addlistener(obj.dataGeneratorObj,'NewExperiment',@eventListenDisplay)
addlistener(obj.dataGeneratorObj,'NewTrial',@eventListenDisplay)
addlistener(obj.dataGeneratorObj,'NewStimulus',@eventListenDisplay)
addlistener(obj.dataGeneratorObj,'NewData',@eventListenDisplay)
