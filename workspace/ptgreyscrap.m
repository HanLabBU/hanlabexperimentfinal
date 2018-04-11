cd('C:\Program Files\Point Grey Research\FlyCapture2')

imaq.internal.Utility.getDeviceList'

NET.addAssembly('mscorlib')

MMsetup_javaclasspath('C:\Micro-Manager-1.4')
import mmcorej.* %http://valelab.ucsf.edu/~MM/doc/mmcorej/allclasses-noframe.html
mmc = CMMCore;
mmc.loadSystemConfiguration('F:\Files\ConfigurationFiles\justham.cfg')
mmc.getDeviceLibraries
mmc.getCameraDevice
mmc.getDeviceAdapterNames

cfg = mmcorej.Configuration;
methods(cfg)

mmstud = import('org.micromanager.MMStudio');
gui = MMStudio(false);
gui.show;
mmc = gui.getCore;
acq = gui.getAcquisitionEngine;

% C:\Program Files\MATLAB\R2014b\toolbox\imaq\imaqextern\drivers\win64\dcam\1394camera646\1394camera


