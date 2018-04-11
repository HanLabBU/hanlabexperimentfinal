function zipProject()
% Mark Bucklin
% This function should be called to save a project as a zip file containing all mfiles in the
% project folder and all subfolders.


defaultProjectDirectory = fileparts(which('ImageAcquisitionGUI.m'));% ...
% 		'C:\Users\monkey\Documents\MATLAB\Gabriela';
defaultBackupDirectory = fileparts(which('ImageAcquisition_ProjectNotes.txt'));%...
% 		'C:\Users\monkey\Documents\MATLAB\Project Backups';
defaultZipFileName = ['Imaq_Backup_',...
		datestr(now,'yyyymmmdd_HHMMPM'),'.zip'];


if isdir(defaultProjectDirectory)
		projDir = defaultProjectDirectory;
else
		projDir =  uigetdir(pwd,'Select Project Directory to Zip:');
end

[zipFileName,zipPath] = uiputfile('*.zip',...
		'Save Zip File to: ', ...
		fullfile(defaultBackupDirectory,defaultZipFileName));

if ~isempty(zipFileName) ...
				&& ~isempty(zipPath) ...
				&& ~isempty(projDir)
		zip(fullfile(zipPath,zipFileName),projDir)
end
