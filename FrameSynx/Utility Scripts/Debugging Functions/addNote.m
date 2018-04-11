function addNote( )
%ADDNOTE Summary of this function goes here
%   Detailed explanation goes here


backupDirectory = ...
		'C:\Users\monkey\Documents\MATLAB\Project Backups';
notesFileName = 'ImageAcquisition_ProjectNotes.txt';
dateStamp = datestr(now,'yyyymmmdd_HHMMPM');

options = struct(...
		'Resize','on',...
		'WindowStyle','normal');
prompt = ['Record a project note to file: ',notesFileName];
name = ['Project Note Addition: ',dateStamp];
numlines = [4 60];
		
uiNote = char(inputdlg(prompt, name, numlines ,{''}, options));

fid = fopen(fullfile(backupDirectory,notesFileName),'a');
if fid <0
		[notesFileName, backupDirectory] = uiputfile(...
				'*.txt','Find or make notes file: ',fullfile(backupDirectory,notesFileName));
		fid = fopen(fullfile(backupDirectory,notesFileName),'a');
end
try
		fprintf(fid,'%s\r\n%s\r\n\r\n',dateStamp,uiNote);
		fclose(fid);
catch me
		warning(me.message)
end
end

