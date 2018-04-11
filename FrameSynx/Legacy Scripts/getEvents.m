function [time,evts] = getEvents(headers,data,type,channel)

defs = getPLXdefs;

% get only spike triggers
evts = find([data(:).Type] == type & [data(:).Channel] == channel);

time = [data(evts).timeStampSeconds];
