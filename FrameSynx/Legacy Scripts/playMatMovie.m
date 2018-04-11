%
% PLAYMATMOVIE plays a movie stored in a file or a frames struct
%   H = PLAYMATMOVIE(frames) takes in either a movie file name or a
%   valid frames struct and returns the handle to the movie figure
%
%   H = PLAYMATMOVIE(frames,'arg1',val1,'arg2',val2...) where arg1 can be:
%       * CLIP      - (default=0) specify removal of border pixels
%       * RANGE     - ([-2 2]) specify range of values for intensity scaling
%       * STDSCALE  - (true) specify that the range is in std units
%       * NOMEAN    - (true) subtract mean from each frame
%       * DIVBYMEAN - (false) divide the entire movie by its mean
%
function fig_movie = playMatMovie(images,varargin)
 
fileName = [];
if ischar(images)
    fileName = images;
    [F,T,S,C,images] = loadMatMovie(frames);
elseif isnumeric(images) 
    fileName = 'Frames In';
else 
    error([mfilename ': frames must be either a movie file name or a valid frames struct']);
end

range = [-2 2];
clip = 0;
nomean = true;
stdscale = true;
divbymean = false;

for n = 1:2:length(varargin)
    switch upper(varargin{n})
        case 'CLIP'
            clip = varargin{n+1};
        case 'RANGE'
            range = varargin{n+1};
        case 'STDSCALE'
            stdscale = varargin{n+1};
        case 'NOMEAN'
            nomean = varargin{n+1};
        case 'DIVBYMEAN'
            divbymean = varargin{n+1};
        otherwise
            error('%s: I kill you... for what you give to me wrong argument: %s?',mfilename,varargin{n});
    end
end

sz = sqrt(size(images,1));

fig_movie = figure('MenuBar','none','Name',fileName,'DoubleBuffer','on');
set(fig_movie,'Position',[100 400 600 500],'Tag','fig_movie');
btn_ok = uicontrol('String','OK','Position',[20 20 60 20],'Style','pushbutton','Enable','on','UserData',-1,'Callback',@okCallback);
btn_cancel = uicontrol('String','Cancel','Position',[90 20 60 20],'Style','pushbutton','Enable','on','UserData',-1,'Callback',@cancelCallback);
btn_roi = uicontrol('String','ROI','Position',[160 20 60 20],'Style','pushbutton','Enable','on','UserData',-1,'Callback',@roiCallback);

% draw the first frame and put a frame number in the lower right hand corner as well as the synch info
txt_info = uicontrol('String','blah blah','Position',[460 20 120 20],'Style','text','UserData',-1);

if divbymean
    images = images./repmat(mean(images,2),1,size(images,2));
end

img_flat = double(images(:,1));    
img_mean = mean(img_flat);
img_std = std(img_flat);

ax_img = axes;
axis image;
% h_img = imagesc(frames(1).image',img_mean+2*[-img_std img_std]);
img = reshape(images(:,1),sz,sz);
if nomean
    img = img - mean(img(:));
end
if stdscale
    img = img./std(img(:));
end

h_img = imagesc(img(clip+1:end-clip,clip+1:end-clip)',range);
colormap(gray(256));

ROI = struct('number',0,'figure',-1);

handles = struct('fig_movie',fig_movie,'btn_ok',btn_ok,'btn_cancel',btn_cancel,'btn_roi',btn_roi,'txt_info',txt_info,...
    'img_std',img_std,'img_mean',img_mean,...
    'ax_img',ax_img,'h_img',h_img,'curFrame',1,'images',images,'clip',clip,'range',range,'nomean',nomean,'stdscale',stdscale',...
    'sz',sz,'ROI',ROI);

set(handles.txt_info,'String',sprintf('Frame %i of %i',handles.curFrame,size(handles.images,2)));

set(fig_movie,'UserData',handles);
set(fig_movie,'KeyPressFcn',@playMatMovieKeyPressCallback);
% set(fig_movie,'ButtonDownFcn','playMatMovieBtnDownCallback');

function cancelCallback(h,varargin)

handles = get(gcbf,'UserData');
set(handles.btn_ok,'UserData',2);

function okCallback(h,varargin)

handles = get(gcbf,'UserData');
set(handles.btn_ok,'UserData',1);

function roiCallback(h,varargin)

handles = get(gcbf,'UserData');

sprintf('region%03i',handles.ROI.number),

handles.ROI.number = handles.ROI.number + 1;
temp = roipoly';
handles.ROI.(sprintf('region%03i',handles.ROI.number)) = temp(:);
handles.ROI.(sprintf('trace%03i',handles.ROI.number)) = mean(handles.images(handles.ROI.(sprintf('region%03i',handles.ROI.number)),:));

figure;
subplot(1,2,1);
imagesc(temp);
title(sprintf('region%03i',handles.ROI.number));
subplot(1,2,2);
plot(handles.ROI.(sprintf('trace%03i',handles.ROI.number)));
title(sprintf('trace%03i',handles.ROI.number));

figure(handles.fig_movie);
set(handles.fig_movie,'UserData',handles);


evalin('base','TEMP99999999999 = get(gcf,''UserData''); CUR_MOVIE_ROIS = TEMP99999999999.ROI; clear TEMP99999999999;');

function playMatMovieKeyPressCallback(h,varargin)

handles = get(gcbf,'UserData');
key = get(gcbf,'CurrentCharacter');
% fprintf('%s key pressed\n',key);

switch key
case '6'
    handles.curFrame = handles.curFrame + 1;
case '4'
    handles.curFrame = handles.curFrame - 1;
end

if handles.curFrame >= size(handles.images,2)
    handles.curFrame = size(handles.images,2);
elseif handles.curFrame <= 0
    handles.curFrame = 1;
end

set(handles.txt_info,'String',sprintf('Frame %i of %i',handles.curFrame,size(handles.images,2)));

clip = handles.clip;
img = reshape(handles.images(:,handles.curFrame),handles.sz,handles.sz);
if handles.nomean
    img = img - mean(img(:));
end

if handles.stdscale
    img = img/std(img(:));
end

set(handles.h_img,'cdata',img(clip+1:end-clip,clip+1:end-clip)');
colormap(gray(256));

set(gcbf,'UserData',handles);

