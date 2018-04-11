function value = findArg( argname, varargin )
%findArg  find a specific property value from a property-value pairs list
%
%   value = findParentArg(propname,varargin) parses the inputs as property-value
%   pairs looking for the named property. If found, the corresponding
%   value is returned. If not found an empty array is returned.
%
%   Examples:
%   >> uiextras.findArg('Parent','Padding',5,'Parent',1,'Visible','on')
%   ans =
%     1

%   Copyright 2009 The MathWorks Ltd.
%   $Revision: 199 $    $Date: 2010-06-18 15:55:16 +0100 (Fri, 18 Jun 2010) $

error( nargchk( 1, inf, nargin ) );

value = [];
if nargin>1
    props = varargin(1:2:end);
    values = varargin(2:2:end);
    if ( numel( props ) ~= numel( values ) ) || any( ~cellfun( @ischar, props ) )
        error( 'UIExtras:FindArg:BadSyntax', 'Arguments must be supplied as property-value pairs' );
    end
    myArg = find( strcmpi( props, argname ), 1, 'last' );
    if ~isempty( myArg )
        value = values{myArg};
    end
end
