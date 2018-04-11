close all
% Mean Image (averaged over first 25 frames)
c.hires.openap = mean(mat4.dataSample.red(:,:,:,2),4);
c.hires.closedap = mean(mat3.dataSample.red(:,:,:,2),4);
c.lores.openap = mean(mat5.dataSample.green(:,:,:,2),4); % (green and red are switched)
c.lores.closedap = mean(mat2.dataSample.red(:,:,:,2),4);
% Binned Images
ind = 1:4:1024-3;
im = c.hires.closedap;
c.hires.binned_closedap = im(ind,ind)+im(ind+1,ind+1)+im(ind+2,ind+2)+im(ind+3,ind+3);
im = c.hires.openap;
c.hires.binned_openap = im(ind,ind)+im(ind+1,ind+1)+im(ind+2,ind+2)+im(ind+3,ind+3);
% Plot Figures
figure,imagesc(c.hires.binned_closedap), title('Software Binning: Small Aperture')
figure,imagesc(c.hires.binned_openap), title('Software Binning: Large Aperture')
figure,imagesc(c.lores.closedap), title('Hardware Binning: Small Aperture')
figure,imagesc(c.lores.openap), title('Hardware Binning: Large Aperture')
% Get Signal and Noise ROIs
h = msgbox('Choose Noise ROI');
waitfor(h)
noiserect = imrect(gca);
wait(noiserect)
noise_mask = noiserect.createMask();
h = msgbox('Choose Signal ROI');
waitfor(h)
signalrect = imrect(gca);
wait(signalrect)
signal_mask = signalrect.createMask();
% Noise
n.lo.open = std2(c.lores.openap(noise_mask));
n.lo.closed = std2(c.lores.closedap(noise_mask));
n.hi.open = std2(c.hires.binned_openap(noise_mask));
n.hi.closed = std2(c.hires.binned_closedap(noise_mask));
% Average
a.lo.open = mean2(c.lores.openap);
a.lo.closed = mean2(c.lores.closedap);
a.hi.open = mean2(c.hires.binned_openap);
a.hi.closed = mean2(c.hires.binned_closedap);
% Max (Signal)
s.lo.open = max(c.lores.openap(signal_mask));
s.lo.closed = max(c.lores.closedap(signal_mask));
s.hi.open = max(c.hires.binned_openap(signal_mask));
s.hi.closed = max(c.hires.binned_closedap(signal_mask));
% SNR
snr.lo.open  = s.lo.open /n.lo.open;
snr.lo.closed  = s.lo.closed /n.lo.closed;
snr.hi.open  = s.hi.open /n.hi.open;
snr.hi.closed  = s.hi.closed /n.hi.closed;
% Display
fprintf('SNR\n')
fprintf('Hardware Binning: Small Aperture: %0.2f\n',snr.lo.closed)
fprintf('Hardware Binning: Large Aperture: %0.2f\n',snr.lo.open)
fprintf('Software Binning: Small Aperture: %0.2f\n',snr.hi.closed)
fprintf('Software Binning: Large Aperture: %0.2f\n',snr.hi.open)



