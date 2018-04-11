classdef GUI < hgsetget & dynamicprops
	
	
	
	
	
	
	
	properties
		mainFig
		mainMenu
		mainObj
	
	end
	
	
	
	
	
	
	events
		
	end
	
	
	
	
	
	
	methods
		function obj = GUI(mainobj)
			obj.mainFig = figure(...
				'units','pixels',...
				'position',obj.pos.mainfig,...
				'menubar','none',...
				'name','Das Lab Image Acquisition',...
				'numbertitle','off',...
				'tag','mainfig',...
				'closerequestfcn',@(src,evnt)closeFigFcn(obj,src,evnt),...
				'units','pixels',...
				'numbertitle','off',...
				'resize','off');
		end
	end
	
	
	
	
	
	
	
	
end