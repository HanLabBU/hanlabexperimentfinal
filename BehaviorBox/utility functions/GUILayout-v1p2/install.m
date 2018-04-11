function install()
%install  add the layout package to the MATLAB path
%
%   install() adds the necessary folders to the MATLAB path for the layout
%   tools to be used from anywhere.
%
%   See also: uninstall

%   Copyright 2008-2009 The MathWorks Ltd.
%   $Revision: 199 $    $Date: 2010-06-18 15:55:16 +0100 (Fri, 18 Jun 2010) $

thisdir = fileparts( mfilename( 'fullpath' ) );

addpath( thisdir );
addpath( fullfile( thisdir, 'layoutHelp' ) );
addpath( fullfile( thisdir, 'Patch' ) );

savepath();
