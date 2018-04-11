function varargout = callCallback( callback, varargin )
%callCallback  try to call a callback method
%
%   uiextras.callback(@FCN,ARG1,ARG2,...) calls the function
%   specified by the supplied function handle @FCN, passing it the supplied
%   extra arguments.
%
%   uiextras.callback(FCNCELL,ARG1,ARG2,...) calls the function
%   specified by the first item in cell array FCNCELL, passing the extra
%   arguments ARG1, ARG2 etc before any additional arguments in the cell
%   array.
%
%   uiextras.callback(FUNCNAME,ARG1,ARG2,...) calls the function
%   specified by the string FUNCNAME, passing the supplied extra arguments.
%
%   [OUT1,OUT2,...] = uiextras.callback(...) also captures return
%   arguments. Note that the function called must provide exactly the right
%   number of output arguments.
%
%   Use this function to handle firing callbacks from widegts.

%   Ben Tordoff
%   Copyright 2009 The MathWorks, Inc.
%   $Revision: 199 $Date: 2009-12-09$

if isempty(callback)
    return;
end

% Handle all the different ways a callback might be specified
if iscell(callback)
    if nargin>1
        inargs = [ callback(1), varargin{:}, callback(2:end) ];
    else
        inargs = callback;
    end
    
    
elseif ischar(callback) && any(ismember(callback, ' ='))
    % sometimes users specify an expression rather than a function
    eval(callback);
    return;
    
else
    if nargin>1
        inargs = [ {callback}, varargin ];
    else
        inargs = {callback};
    end
end

% Now call it!
[varargout{1:nargout}] = feval( inargs{:} );

end % callCallback
