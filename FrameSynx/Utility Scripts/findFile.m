function findFile(fname)

for n = 1:100	
	cd ..
end
topLevelDirectory = pwd;
topLevelDirectory = uigetdir(topLevelDirectory,...
	'Choose the top-level (root) directory to begin the search from');

d = dir(topLevelDirectory);


keyboard







