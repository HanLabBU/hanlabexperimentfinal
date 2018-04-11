stimfile = struct(...
		'Stimulus',struct(...
		'Type','STIMULUS_IMAGE',...
		'Response',2),...
		...
		'ImageSettings',struct(...
		'Width',3.12,...
		'Height',3.13,...
		'Path','C:\stimuli\YodaStim_03_20_10\double_gabor_100c_75sig_165_075.bmp')...
		)

stimfilename = char(inputdlg('Name the file:'));
if ~strcmp(stimfilename(end-4:end),'.stm');
		stimfilename = [stimfilename,'.stm'];
end
fid = fopen(stimfilename,'wt+');
settingCategories = fieldnames(stimfile);
for n = 1:length(settingCategories)
		setcat = settingCategories{n};		
		settingStruct = stimfile.(sprintf('%s',setcat));
		fprintf(fid,'[%s]\r\n',setcat)
		settings = fieldnames(settingStruct);
		for m = 1:length(settings)
				settingName = settings{m};
				settingValue = stimfile.(sprintf('%s',setcat)).(sprintf('%s',settingName));
				if ~ischar(settingValue)
						settingValue = num2str(settingValue);
				end
				fprintf(fid,'%s = %s\r\n',settingName,settingValue)
		end
		fprintf(fid,'\r\n')
end
fclose(fid)