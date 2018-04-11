function uninstall()
%uninstall  remove the layout package from the MATLAB path
%
%   uninstall() removes the layout tools from the MATLAB path.
%
%   See also: install

%   Copyright 2008-2009 The MathWorks Ltd.
%   $Revision: 199 $    $Date: 2010-06-18 15:55:16 +0100 (Fri, 18 Jun 2010) $

thisdir = fileparts( mfilename( 'fullpath' ) );

rmpath( thisdir );
rmpath( fullfile( thisdir, 'layoutHelp' ) );
rmpath( fullfile( thisdir, 'Patch' ) );

savepath();