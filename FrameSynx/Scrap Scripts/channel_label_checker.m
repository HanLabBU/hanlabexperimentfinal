clc

for n=1:15
		a_trim = a(1:floor(numel(a)/n)*n);
		a_reshape = reshape(a_trim,n,[]);
		difmat = a_reshape(:,2:end) - a_reshape(:,1:end-1);	
		discrep(n) = sum(abs(difmat(:)));
end



% for n=1:20
% 		t = a(1:n);
% 		k = strfind(a,t);
% 		disp(t)
% 		disp(length(k))
% end