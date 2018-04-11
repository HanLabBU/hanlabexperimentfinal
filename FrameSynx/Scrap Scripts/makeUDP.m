function makeUDP(compname)
if isempty(compname)
	  compname = 'analysis2';
end
[stimName,stimIP] = resolvehost(compname);
udpListener = udp(stimIP);
set(udpListener,...
	  'DatagramReceivedFcn',@messageReceivedFcn,...
	  'DatagramTerminateMode','off',...
	  'ByteOrder','bigEndian',...
	  'InputBufferSize',1024);
fopen(udpListener)	






