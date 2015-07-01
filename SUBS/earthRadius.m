function r = earthRadius(unitOfLength)
%Mean radius of planet Earth
%
%   R = earthRadius returns the scalar value 6371000, the mean radius
%   of the Earth in meters.
%
%   R = earthRadius(unitOfLength) returns the mean radius of the Earth
%   in the requested units of length. The input unitOfLength may be any
%   string accepted as a unit of length by the UNITSRATIO function.
%
%   Examples
%   --------
%   earthRadius             % Returns 6371000
%   earthRadius('meters')   % Returns 6371000
%   earthRadius('km')       % Returns 6371
%
%   See also UNITSRATIO.

% Copyright 2009 The MathWorks, Inc.
% $Revision: 1.1.6.1 $  $Date: 2009/12/28 04:33:38 $

r = 6371000;
if nargin > 0
    r = r * unitsratio(unitOfLength, 'meter');
end
