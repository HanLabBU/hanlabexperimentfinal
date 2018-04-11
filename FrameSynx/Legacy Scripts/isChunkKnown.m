function t = isChunkKnown(chunkName)
% check the list of known chunks for chunkName
chunks = {'FRAM','cost','ISOI','SOFT','DATA','COST','COMP','HARD','ROIS','SYNC','epst','EPST','GREE','EXST'};
t = ~isempty(find(strcmp(chunks,chunkName)));