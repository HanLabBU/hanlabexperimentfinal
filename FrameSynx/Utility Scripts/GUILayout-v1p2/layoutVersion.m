function [version, versionDate] = layoutVersion()
%layoutVersion  get the toolbox version and date
%
%   V = layoutVersion() returns just the version string
%
%   [V,D] = layoutVersion() returns both the version string and the date of
%   creation (format is ISO8601, i.e. YYYY-MM-DD)
%
%   Examples:
%   >> [v,d] = layoutVersion()
%   v = '1.0'
%   d = '2010-05-28'
%
%   See also: layoutRoot

%   Copyright 2009-2010 The MathWorks Ltd.
%   $Revision: 199 $    
%   $Date: 2010-06-18 15:55:16 +0100 (Fri, 18 Jun 2010) $

version = '1.2';
versionDate = '2010-06-18';

% version = '1.1';
% versionDate = '2010-06-09';

% version = '1.0';
% versionDate = '2010-05-28';

% version = '0.4';
% versionDate = '2010-05-19';

% version = '0.3';
% versionDate = '2010-03-10';

% version = '0.2';
% versionDate = '2010-01-06';
