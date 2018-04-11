function stackup(varargin)


n=1;
m=1;
while n <= nargin
		if ishandle(varargin{n})
				h(m) = varargin{n};
				m=m+1;
		end
		n=n+1;
end

for n=2:length(h)
		setpixelposition(h(n),getpixelposition(h(n-1))+[0 30 0 0]);
end

