% GetShiftTemplt

% Selects template for later file alignment. Interactively / with mouse, selects ROI from BAND PASS FILTERED
%   template file. Expects single file name & root directory for the day's experiments
%
% Sep 1 2006: only use image divided by low-pass-fltred version to even out the illumination. NO LONGER use band-pass filter
%   (See CumOI_Processing notes)

function GetShiftTemplt(RootDir, filename, optionsIn, ChgOptions)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setting up basic options, defining ROI struct etc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% NOTE: ROI.w, ROI.h defined as DIFF betw last & first index. 
%   Thus an ROI with 2 columns has WIDTH = ROI.w = 1.
ROI = struct(...
    'x','double',...
    'y','double',...
    'w','double',...
    'h','double');

if(nargin < 4)  ChgOptions = 1; end
if(nargin < 3)  optionsIn = ''; end
if(nargin < 2)  filename = '*.mat'; end
if(nargin < 1)
    fprintf('USAGE: GetShiftTemplt(RootDir, filename, optionsIn)\noptionsIn: struct\n')
    return
end

if ((nargin == 2) | ~(isstruct(optionsIn)) | (ChgOptions == 1))      
    optionsIn.Prompt = 'ON'; optionsIn = getOptionsIn(RootDir, optionsIn);   
end;

flAry = dir([RootDir optionsIn.ImgDirIn filename]);
if (isempty(filename) | (length(flAry) ~= 1))
    if ((length(flAry) > 1) & (optionsIn.NFile ~= 0))        filename = flAry(optionsIn.NFile).name;
    else    [filename,path] = uigetfile('*.mat','Pick Img File for TEMPLATE ...');
    end
end



% If ImgDirOut doesn't exist, create. NOTE: Need to break up absolute dirnm
if  ~(exist([optionsIn.RootDir optionsIn.TmpltDir]) == 7)   mkdir(optionsIn.RootDir, optionsIn.TmpltDir); end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Start on the input image file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Flnm = strcat(optionsIn.RootDir, optionsIn.ImgDirIn, filename)

switch optionsIn.Val_MatFormat
case    {1, 2, 2.1, 3, 4, 5}
    load (Flnm, 'soft', 'images');
case    0
    load (Flnm, 'soft' ,'frames');
end

Nx = soft.XSize;
Ny = soft.YSize;
if ((Nx ~= optionsIn.Nx) | (Ny ~= optionsIn.Ny))
    fprintf('******************************\nFILE SIZE MISMATCH\n******************************\n\n');
    fprintf('Input file size: %d X %d: different from default optionsIn %d X %d\nEnter rescaled filter parameters?', ...
        Nx, Ny, optionsIn.Nx, optionsIn.Ny);
    optionsIn.Prompt = 'ON';    optionsIn.Nx = Nx; optionsIn.Ny = Ny; 
    optionsIn = getOptionsIn(RootDir, optionsIn);
end

nFrame = optionsIn.NFrame;


% ChangeFilterParams = 1;
% while (ChangeFilterParams)

	%%%%%%%%%%%%%%%%%%%%%%%%%% Filter image %%%%%%%%%%%%%%%%%%
	% First look for appropriate filters; if they don't exist, create them
	% If there is a stored optionsIn, use that; replace any fields with valid optionsIn fields later. If not, use valid optionsIN or dflt
	ShiftFltr_Equalizing_File = sprintf('Flt_Lo_%d_%d_%d.mat', optionsIn.ShiftFltr_Equalizing, Nx, Ny);
	disp(['Looking for ' ShiftFltr_Equalizing_File ' to filter / equalize illumination']);
	if length(dir([optionsIn.FltrDir ShiftFltr_Equalizing_File])) == 1       
        load([optionsIn.FltrDir ShiftFltr_Equalizing_File]);   Fltr_Equalizing = Filter; clear Filter; 
	else
        Fltr_Equalizing = MakeFilter(optionsIn.ShiftFltr_Equalizing, 0, ShiftFltr_Equalizing_File, optionsIn);
	end
	
	BandPassFltr_File = sprintf('Flt_%d_%d_%d_%d.mat', optionsIn.ShiftFltr_Lo, optionsIn.ShiftFltr_Hi, Nx, Ny);
	disp(['Looking for ' BandPassFltr_File ' to band pass filter template']);
	if length(dir([optionsIn.FltrDir BandPassFltr_File])) == 1       
        load([optionsIn.FltrDir BandPassFltr_File]);   Fltr_BandPass = Filter;  clear Filter;
	else
        Fltr_BandPass = MakeFilter(optionsIn.ShiftFltr_Lo, optionsIn.ShiftFltr_Hi, BandPassFltr_File, optionsIn);
	end
	
	
	% Divide by lo pass filtered image for evening out the light
	switch optionsIn.Val_MatFormat
	case    {1, 2, 2.1, 3, 4, 5}
        ImgFltr = real(ifft2(fft2(reshape(images(:,nFrame), [Nx Ny])) .* Fltr_Equalizing));
        buf2 = reshape(images(:,nFrame), [Nx Ny])./ImgFltr;
	case    0
        ImgFltr = real(ifft2(fft2(frames(nFrame).image) .* Fltr_Equalizing));
        buf2 = frames(nFrame).image ./ ImgFltr;
	end
	
	% Show figure without further bandpass filtering, as standard
	[BufMean, BufSD] = getBufMeanSD(buf2, Nx, Ny);
	fig_Orig = figure('WindowStyle','normal','MenuBar','none','Name','Illumination-equalized image BEFORE band pass filtering');
	set(fig_Orig, 'Units', 'pixels', 'Position',[100 100 600 600]);
	imagesc(buf2', [BufMean - BufSD*2.5 BufMean+BufSD*2.5]); colormap(gray(256));
	
	% Next, further band-pass the image, IF DESIRED
	if strcmp(optionsIn.ShftFilter, 'LO_PASS_BAND_PASS')
		buf1 = fft2(buf2) .* Fltr_BandPass;
		buf2 = real(ifft2(buf1));   clear buf1;
        [BufMean, BufSD] = getBufMeanSD(buf2, Nx, Ny);
	end
	
	% Set up figure and handles to control items (buttons)
	fig_Tmplt = figure('WindowStyle','normal','MenuBar','none','Name','TemplateSelect (after optional band pass filtering)');
	set(fig_Tmplt, 'Units', 'pixels', 'Position',[1024 100 600 600]);
	
	btn_ok = uicontrol('String','OK','Position',[20 20 60 20],'Style','pushbutton','Enable','off','Callback','tmpltOk','UserData',-1);
	btn_redo = uicontrol('String','Redo','Position',[90 20 60 20],'Style','pushbutton','Enable','off','Callback','tmpltRedo','UserData',-1);
	
	% initialize the handles structure
	handles = struct('fig_Tmplt',fig_Tmplt,'btn_ok',btn_ok,'btn_redo',btn_redo);
	
	% add the handles to fig_Tmplt's UserData
	set(fig_Tmplt,'UserData',handles);
	
	% Draw scaled image. NOTE: imagesc of TRANPOSED image file. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	imagesc(buf2', [BufMean - BufSD*2.5 BufMean+BufSD*2.5]);
	colormap(gray(256));
	
	% Interactively obtain ROI until satisfied.
	while(get(btn_ok, 'UserData') ~= 1)
        
		[x, y] = ginput(2); % NOTE: ginput gives true [x,y], NOT in array notation where x,y interchanged
		ROI.x = fix(x(1));
		ROI.y = fix(y(1));
		ROI.w = fix(x(2) - x(1));
		ROI.h = fix(y(2) - y(1));
	
		fprintf('Rect: x: %d, y: %d, w: %d, h: %d\n', ROI.x, ROI.y, ROI.w, ROI.h);
		rectangle('position', [ROI.x, ROI.y, ROI.w, ROI.h]);
		
		% Enable buttons on original Templt figure, reset UserData
        set(btn_ok, 'UserData', -1);    
        set(btn_ok, 'Enable', 'on');
		set(btn_redo, 'Enable', 'on');
		
		% Draw separate figure with selected template
        Templt = real(buf2(ROI.x:ROI.x+ROI.w, ROI.y:ROI.y+ROI.h));
		fig_TmpltTemp = figure('Name', 'Template Detail', 'Position', [1024, 20, (2*ROI.w + 50), (2*ROI.h + 50)]);
		imagesc(Templt');
		colormap(gray)
		
		% wait unitil we are done selecting files and ok or cancel button is pushed. Close fig, reset buttons
		waitfor(btn_ok,'UserData'); % Waits until ANY change occurs in the given item
		close(fig_TmpltTemp);
        set(btn_ok, 'Enable', 'on');
		set(btn_redo, 'Enable', 'on');
	end
	
	close(fig_Tmplt);
    close(fig_Orig);
    
save(strcat(optionsIn.RootDir, optionsIn.TmpltDir, optionsIn.TmpltFile), 'Templt', 'ROI');

%
% TMPLTOK Callback Function for the OK button on GetShiftTemplt
%
function tmpltOk()

handles = get(gcbf,'UserData');
set(handles.btn_ok,'UserData',1);

%
% TMPLTREDO Callback Function for the REDO button on GetShiftTemplt
%
function tmpltRedo()
handles = get(gcbf,'UserData');
set(handles.btn_ok,'UserData',0);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper function to set proper mean, SD for clipping / imagesc display: avoiding image edges to get good imagesc dynamic range

function [BufMean, BufSD] = getBufMeanSD(buf, Nx, Ny);

buf_temp = buf(floor(Nx/10)+1:Nx-floor(Nx/10),floor(Ny/10)+1:Ny-floor(Ny/10));
BufMean = mean(buf_temp(:));
BufSD = std(buf_temp(:));

