function setax

axis image ij off

a = jet(256);
a(1,:) = 0;
a(256,:) = 1;
colormap(a)


