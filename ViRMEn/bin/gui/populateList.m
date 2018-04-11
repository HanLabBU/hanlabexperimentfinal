function lst = populateList(name)

switch name
    case 'listShapes'
        mfile = mfilename('fullpath');
        path = fileparts(mfile);
        shapes = dir([path filesep '..' filesep '..' filesep 'shapes' filesep '*.m']);
        lst = [];
        usedFiles = {};
        for ndx = 1:length(shapes)
            lst(ndx).name = shapes(ndx).name(1:end-2); %#ok<AGROW>
            if length(lst(ndx).name)>5 && strcmp(lst(ndx).name(1:5),'shape')
                lst(ndx).callback = 'addShape'; %#ok<AGROW>
                lst(ndx).callbackArgument = lst(ndx).name; %#ok<AGROW>
                lst(ndx).name = lst(ndx).name(6:end); %#ok<AGROW>
                
                needIcon = false;
                if ~exist([path filesep 'icons' filesep 'shapes' filesep lst(ndx).callbackArgument '.png'],'file')
                    needIcon = true;
                else
                    dirIcon = dir([path filesep 'icons' filesep 'shapes' filesep lst(ndx).callbackArgument '.png']);
                    dirClass = dir([path filesep '..' filesep '..' filesep 'shapes' filesep lst(ndx).callbackArgument '.m']);
                    if dirClass.datenum > dirIcon.datenum
                        needIcon = true;
                    end
                end
                usedFiles{end+1} = [lst(ndx).callbackArgument '.png']; %#ok<AGROW>
                if needIcon
                    testObj = eval(lst(ndx).callbackArgument);
                    testObj.x = testObj.iconLocations(:,1);
                    testObj.y = testObj.iconLocations(:,2);
                    fig = figure('visible','off','units','pixels','position',[100 100 128 128]);
                    subplot('position',[0 0 1 1]);
                    [x y] = coords2D(testObj);
                    plot(x,y,'k');
                    axis tight
                    axis equal
                    axis off
                    set(fig,'color','w');
                    xl = xlim;
                    yl = ylim;
                    xlim([xl(1)-range(xl)*0.1 xl(2)+range(xl)*0.1]);
                    ylim([yl(1)-range(yl)*0.1 yl(2)+range(yl)*0.1]);
                    f = getframe;
                    a = imresize(double(f.cdata),[16 16]);
                    a = (a-min(a(:)))/median(a(:)-min(a(:)))*240;
                    a(a>240)=240;
                    a = uint8(a);
                    delete(fig)
                    imwrite(a,[path filesep 'icons' filesep 'shapes' filesep lst(ndx).callbackArgument '.png']);
                end
                lst(ndx).icon = ['shapes' filesep lst(ndx).callbackArgument]; %#ok<AGROW>
            end
        end
        mt = dir([path filesep 'icons' filesep 'shapes' filesep '*.png']);
        for ndx = 1:length(mt)
            indx = 0;
            for f = 1:length(usedFiles)
                if strcmp(usedFiles{f},mt(ndx).name)
                    indx = f;
                end
            end
            if indx == 0
                delete([path filesep 'icons' filesep 'shapes' filesep mt(ndx).name]);
            end
        end
    case 'listObjects'
        mfile = mfilename('fullpath');
        path = fileparts(mfile);
        shapes = dir([path filesep '..' filesep '..' filesep 'objects' filesep '*.m']);
        lst = [];
        usedFiles = {};
        for ndx = 1:length(shapes)
            lst(ndx).name = shapes(ndx).name(1:end-2); %#ok<AGROW>
            if length(lst(ndx).name)>6 && strcmp(lst(ndx).name(1:6),'object')
                lst(ndx).callback = 'addObject'; %#ok<AGROW>
                lst(ndx).callbackArgument = lst(ndx).name; %#ok<AGROW>
                lst(ndx).name = lst(ndx).name(7:end); %#ok<AGROW>
                
                needIcon = false;
                if ~exist([path filesep 'icons' filesep 'objects' filesep lst(ndx).callbackArgument '.png'],'file')
                    needIcon = true;
                else
                    dirIcon = dir([path filesep 'icons' filesep 'objects' filesep lst(ndx).callbackArgument '.png']);
                    dirClass = dir([path filesep '..' filesep '..' filesep 'objects' filesep lst(ndx).callbackArgument '.m']);
                    if dirClass.datenum > dirIcon.datenum
                        needIcon = true;
                    end
                end
                usedFiles{end+1} = [lst(ndx).callbackArgument '.png']; %#ok<AGROW>
                if needIcon
                    testObj = eval(lst(ndx).callbackArgument);
                    testObj.x = testObj.iconLocations(:,1);
                    testObj.y = testObj.iconLocations(:,2);
                    fig = figure('visible','off','units','pixels','position',[100 100 128 128]);
                    subplot('position',[0 0 1 1]);
                    testObj.draw2D;
                    axis equal
                    axis tight
                    axis off
                    set(fig,'color','w');
                    xl = xlim;
                    yl = ylim;
                    rng = max([range(xl) range(yl)]);
                    xlim([mean(xl)-rng*1.1/2 mean(xl)+rng*1.1/2]);
                    ylim([mean(yl)-rng*1.1/2 mean(yl)+rng*1.1/2]);
                    f = getframe;
                    a = imresize(double(f.cdata),[16 16]);
                    a = (a-min(a(:)))/median(a(:)-min(a(:)))*240;
                    a(a>240)=240;
                    a = uint8(a);
                    delete(fig)
                    imwrite(a,[path filesep 'icons' filesep 'objects' filesep lst(ndx).callbackArgument '.png']);
                end
                lst(ndx).icon = ['objects' filesep lst(ndx).callbackArgument]; %#ok<AGROW>
            end
        end
        mt = dir([path filesep 'icons' filesep 'objects' filesep '*.png']);
        for ndx = 1:length(mt)
            indx = 0;
            for f = 1:length(usedFiles)
                if strcmp(usedFiles{f},mt(ndx).name)
                    indx = f;
                end
            end
            if indx == 0
                delete([path filesep 'icons' filesep 'objects' filesep mt(ndx).name]);
            end
        end
    case 'listLayouts'
        layouts = layoutList;
        lst = [];
        for ndx = 1:length(layouts)
            lst(ndx).name = layouts{ndx}.name; %#ok<AGROW>
            lst(ndx).callback = 'changeLayout'; %#ok<AGROW>
            lst(ndx).callbackArgument = ndx; %#ok<AGROW>
            lst(ndx).icon = layouts{ndx}.icon; %#ok<AGROW>
        end
    case 'listExports'
        lst = [];
        lst(1).name = 'World 2D';
        lst(1).icon = 'world';
        lst(2).name = 'World 3D';
        lst(2).icon = 'threeD';
        lst(3).name = 'World wireframe';
        lst(3).icon = 'wireframe';
        lst(4).name = 'Texture';
        lst(4).icon = 'texture';
        for ndx = 1:length(lst)
            lst(ndx).callback = 'export'; %#ok<AGROW>
            lst(ndx).callbackArgument = lst(ndx).name; %#ok<AGROW>
        end
    case 'listEdit'
        lst = [];
        lst(1).name = 'Movement function...';
        lst(1).icon = 'movementFunction';
        lst(1).callbackArgument = 'movementFunction';
        lst(2).name = 'Transformation function...';
        lst(2).icon = 'transformationFunction';
        lst(2).callbackArgument = 'transformationFunction';
        lst(3).name = 'Experiment code...';
        lst(3).icon = 'experimentCode';
        lst(3).callbackArgument = 'experimentCode';
        for ndx = 1:length(lst)
            lst(ndx).callback = 'editCode'; %#ok<AGROW>
        end
end