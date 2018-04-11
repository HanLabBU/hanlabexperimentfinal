
clear csfields bsfields csclass bsclass camsession bhvsession n vf_frame bf_frame

camsession = load(uigetfile('.mat','Choose a CameraSession to Open'));
csfields = fields(camsession);
vfdata = cell.empty(length(csfields),0);
for n=1:length(csfields)
		vf(n,1) = camsession.(sprintf('VideoFile_%i',n));
		vf_frame(n,1) = vf(n).firstFrame;
		vf_frame(n,2) = vf(n).lastFrame;
		vf_frame(n,3) = vf(n).numFrames;
		[data, info] = getFrames(vf(n));
		vfdata{n,1} = data;
		if isstruct(info)
				vfinfo(n,1) = info;
		end
end
vf_frame(:,4) = vf_frame(:,2) - vf_frame(:,1) + 1;
vf_frame(:,5) = vf_frame(:,4) - vf_frame(:,3);

bhvsession = load(uigetfile('.mat','Choose a BehaviorSession to Open'));
bsfields = fields(bhvsession);
bfdata = cell.empty(length(bsfields),0);
for n=1:length(bsfields)
		bf(n,1) = bhvsession.(sprintf('BehaviorFile_%i',n));
		bf_frame(n,1) = bf(n).firstFrame;
		bf_frame(n,2) = bf(n).lastFrame;
		bf_frame(n,3) = bf(n).numFrames;
		[data,info] = getFrames(bf(n));
		bfdata{n,1} = data;
		if isstruct(info)
				bfinfo(n,1) = info;
		end
end
bf_frame(:,4) = bf_frame(:,2) - bf_frame(:,1) + 1;
bf_frame(:,5) = bf_frame(:,4) - bf_frame(:,3);

clear csfields bsfields csclass bsclass camsession bhvsession n