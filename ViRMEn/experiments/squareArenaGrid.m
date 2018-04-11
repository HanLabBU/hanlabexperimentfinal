function code = squareArenaGrid
    % squareArenaGrid   Code for the ViRMEn experiment squareArenaGrid.
    %   code = squareArenaGrid   Returns handles to the functions that ViRMEn
    %   executes during engine initialization, runtime and termination.


    % Begin header code - DO NOT EDIT
    code.initialization = @initializationCodeFun;
    code.runtime = @runtimeCodeFun;
    code.termination = @terminationCodeFun;
    % End header code - DO NOT EDIT



    % --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)

    disp('Initializing...')
     vr.m = udpInterface;
     vr.debugMode = eval(vr.exper.variables.debugMode);

    if ~vr.debugMode
        % Start the DAQ acquisition
        daqreset; %reset DAQ in case it's still in use by a previous Matlab program
        vr.ai = analoginput('nidaq','dev1'); % connect to the DAQ card
        addchannel(vr.ai,0:1); % start channels 0 and 1
        set(vr.ai,'samplerate',1000,'samplespertrigger',inf);
        set(vr.ai,'bufferingconfig',[8 100]);
        set(vr.ai,'loggingmode','Disk');
        vr.tempfile = [tempname '.log'];
        set(vr.ai,'logfilename',vr.tempfile);
        set(vr.ai,'DataMissedFcn',@datamissed);
        start(vr.ai); % start acquisition

        vr.ao = analogoutput('nidaq','dev1');
        addchannel(vr.ao,0);
        set(vr.ao,'samplerate',10000);

        vr.finalPathname = 'C:\Users\tankadmin\Dropbox\virmenLogs';
        vr.pathname = 'C:\Users\tankadmin\Desktop\testlogs';
        vr.filename = datestr(now,'yyyymmddTHHMMSS');
        exper = copyVirmenObject(vr.exper); %#ok<NASGU>
        save([vr.pathname '\' vr.filename '.mat'],'exper');
        vr.fid = fopen([vr.pathname '\' vr.filename '.dat'],'w');
        vr.isStarting = true;

        vr.dio = digitalio('nidaq','dev1');
        addline(vr.dio,0:7,'out');
        start(vr.dio);
    end

    vr.text(1).string = '0';
    vr.text(1).position = [-.14 .1];
    vr.text(1).size = .03;
    vr.text(1).color = [1 0 1];

    vr.text(2).string = '0';
    vr.text(2).position = [-.14 0];
    vr.text(2).size = .03;
    vr.text(2).color = [1 1 0];

    vr.gridSize = eval(vr.exper.variables.gridSize);
    vr.floorWidth = eval(vr.exper.variables.floorWidth);

    vr.targetX = fix(rand*vr.gridSize);
    vr.targetY = fix(rand*vr.gridSize);

    vr.numRewards = 0;
    vr.startTime = now;

    vr.scaling = [13 13];


% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)

    vr.text(2).string = ['TIME ' datestr(now-vr.startTime,'MM.SS')];

    if vr.collision
        vr.dp = vr.dp/1;
    end


    normX = vr.position(1)/vr.floorWidth*vr.gridSize;
    normY = vr.position(2)/vr.floorWidth*vr.gridSize;
    if normX >= vr.targetX && normX <= vr.targetX+1 && normY >= vr.targetY && normY <= vr.targetY+1
        isReward = 1;
    else
        isReward = 0;
    end

    if isReward == 1
        vr.numRewards = vr.numRewards + 1;
        vr.text(1).string = ['REWARDS ' num2str(vr.numRewards)];
    end

    if ~vr.debugMode
        if isReward == 1 || vr.textClicked == 1
            putdata(vr.ao,[0 5 0 0 0 0]');
            start(vr.ao);
            stop(vr.ao);
        end

        measurementsToSave = [now vr.position(1:2) vr.velocity(1:2) vr.targetX vr.targetY isReward];
        if vr.isStarting
            vr.isStarting = false;
            fwrite(vr.fid,length(measurementsToSave),'double');
        end
        fwrite(vr.fid,measurementsToSave,'double');
    end

    if isReward == 1
        tx = vr.targetX;
        ty = vr.targetY;
        while all([tx ty]==[vr.targetX vr.targetY])
            vr.targetX = fix(rand*vr.gridSize);
            vr.targetY = fix(rand*vr.gridSize);
        end
    end

    switch mod(vr.iterations,5)
        case {0,1,3}
            v = mod(fix(vr.iterations),128);
        case 2
            v = mod(fix(vr.iterations/128),64)+128;
        case 4
            v = mod(fix(vr.iterations/8192),64)+192;
    end

    if ~vr.debugMode
        putvalue(vr.dio,v);
    end

    % --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)

    close(vr.m)

    if ~vr.debugMode
        fclose all;
        fid = fopen([vr.pathname '\' vr.filename '.dat']);
        data = fread(fid,'double');
        num = data(1);
        data = data(2:end);
        data = reshape(data,num,numel(data)/num);
        assignin('base','data',data);
        fclose all;
        stop(vr.ai);
        delete(vr.tempfile);

        vr.window.Dispose;
        answer = inputdlg({'Rat number','Comment'},'Question',[1; 5]);
        if ~isempty(answer)
            comment = answer{2}; %#ok<NASGU>
            save([vr.pathname '\' vr.filename '.mat'],'comment','-append')
            if ~exist([vr.pathname '\' answer{1}],'dir')
                mkdir([vr.pathname '\' answer{1}]);
            end
            movefile([vr.pathname '\' vr.filename '.mat'],[vr.finalPathname '\' answer{1} '\' vr.filename '.mat']);
            movefile([vr.pathname '\' vr.filename '.dat'],[vr.finalPathname '\' answer{1} '\' vr.filename '.dat']);
        end

        disp([answer{1} ' - ' num2str(sum(data(end,:)))])
    end