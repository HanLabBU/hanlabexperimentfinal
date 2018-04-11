function portstring = getComPort(portname)

persistent portSettings
nSetPorts = numel(portSettings)+1;
if isempty(portname)
    portname = 'Unspecified';
end
comOptions = instrhwinfo('serial');
if length(comOptions.AvailableSerialPorts) > 1    
    prompt = sprintf('Select %s COM Port',portname);
    selection = menu(prompt,comOptions.AvailableSerialPorts);
    if selection
        portstring = comOptions.SerialPorts{selection};
    else
        portstring = comOptions.SerialPorts{1};
    end
else
    portstring = comOptions.SerialPorts{1};
end
portSettings{nSetPorts,1} = portname;
portSettings{nSetPorts,2} = portstring;