function bin_data = spatialBinData2(data,binfactor)
nrows = size(data,1)/binfactor;
ncols = size(data,2)/binfactor;
try
		bin_data = reshape(...
				sum(...
				reshape(...
				reshape(...
				sum(...
				reshape(...
				data,...
				binfactor,[]),...
				1),...
				nrows,[])',...
				binfactor,[]),...
				1),...
				ncols,[])';
catch
		bin_data = data;
end
end