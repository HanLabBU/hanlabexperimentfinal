%   Function  alignTimecourse
%
%   Returns stim-triggered movie after runline filtering


function alignTimecourse(FileInfo, ind, params, I_FltrStr)
% 
% persistent Buf h_Runline
% 
% % % On the first round of Runline filtering  set up memory space
% if initRunline == 1
%     Buf = zeros(params.Nx * params.Ny, params.L);
%     h_Runline = figure;
% end


Buf = zeros(params.Nx * params.Ny, params.L);;
eval([I_FltrStr ' = Buf;']);

fprintf('File %s: # files: %d; Progress: %03d', I_FltrStr, length(ind), 1); 

% Generate movie sequence
i=0;
for ii = ind
    i = i+1; fprintf('\b\b\b%03d', i); 
    Buf = Buf + getFramesFromSequenceAD(FileInfo,  [FileInfo(ii).FrameStimOn+1-params.Pre    FileInfo(ii).FrameStimOn-params.Pre+params.L]);
end



% Filter with runline
fprintf('\nRunline filtering %s\n', I_FltrStr)
tic; 
eval(['for j=1:params.Nx*params.Ny;' I_FltrStr '(j,:)=runline(Buf(j,:),params.N1, params.N2); end;']); 
toc

% Display w / wo runline
figure; plot([1-params.Pre:params.L-params.Pre], mean(Buf), 'r'); hold on; 
eval(['plot([1-params.Pre:params.L-params.Pre],mean(' I_FltrStr '));']); title(I_FltrStr, 'Interpreter', 'none');