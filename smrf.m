% smrf
% A Simple Morphological Filter for Ground Identification of LIDAR point
% clouds.
%
%
% Syntax
%   [ZIfin R isObject ZIpro ZImin isObjectCell] = smrf(x,y,z,'c',c,'s',s,'w',w);
%
%
% Description
%   SMRF is designed to apply a series of opening operations against a
%   digital surface model derived from a LIDAR point cloud, with the dual
%   purpose of creating a gridded model of the ground surface (ZIfin) (and
%   its referencing matrix R) and a vector of boolean values for each tuple
%   (x,y,z) describing it as either ground (0) or object (1).
%
%   SMRF must be minimally called with x,y,z (all vectors of the same
%   length) as well as a cellsize (c), a slope threshold value (s), and a
%   maximum window size (w).  The slope threshold value governs the
%   identification process, and roughly corresponds to the maximum slope of
%   the terrain you are working with.  The maximum window size defines a
%   window radius (in map units), and corresponds to the size of largest 
%   feature to be removed.
%
%
% Requirements
%   SMRF requires John D'Errico's consolidator.m and inpaint_nans.m files.
%   These are available via the Mathworks File Exchange Program at:
%   http://www.mathworks.com/matlabcentral/fileexchange/8354
%   http://mathworks.com/matlabcentral/fileexchange/4551
%
%   SMRF also requires two subfunctions, createDSM.m and
%   progressiveFilter.m.  These were written as subfunctions for
%   pedagogical purposes.  If the optional 'net cutting' feature is used to
%   remove large buildings with smaller windows, createNet.m must be
%   accessible as well.
%
%   Finally, SMRF also requires that the Mathworks Mapping Toolbox is 
%   installed.
%
%
% Input Parameters
%   x,y,z     - Equally sized vectors defining the points in the cloud
%
%   'c',c     - Cell size, in map units, for the final grid.  The cell size
%               should generally be close to the mean x,y density of your
%               point cloud.
%
%   'xi',xi   - Alternatively, the user can supply a vector of values to 
%   'yi',yi     define the grid
%
%   's',s     - Defines the maximum expected slope of the ground surface
%               Values are given in dz/dx, so most slope values will be in
%               the range of .05 to .30.
%
%   'w',w     - Defines the filter's maximum window radius.  
%   'w',[0 w]   Alternatively, the user can supply his or her own vector of
%   'w',[1:5:w] window sizes to control the open process.  
%   
%   'et',et   - Defines the elevation threshold that expresses the maximum
%               vertical distance that a point may be above the prospective
%               ground surface created after the opening operation is
%               completed.  These values are typically in the range of 0.25
%               to 1.0 meter.  An elevation threshold must be supplied in
%               order for SMRF to return an isObject vector.
%
%   'es',es   - Elevation scaling factor that scales the elevation
%               threshold (et) depending on the slope of the prospective
%               digital surface model (ZIpro) created after the smrf filter
%               has identified all nonground points in the minimum surface.
%               Elevation scaling factors generally range from 0.0 to 2.5,
%               with 1.25 a good starting value.  If no es parameter is
%               supplied, the value of es is set to zero.
%
%   'inpaintMethod',ipm
%               If this parameter is supplied, it controls the argument
%               passed to D'Errico's inpaint_nans method.  The default
%               value is 4.
%
%   'cutNet',netSize
%               Cuts a net of spacing netSize (map coordinates) into ZImin
%               before further processing.  This can help to remove large
%               buildings without the need for extremely large filter
%               windows.  Generally, netSize should be set to the largest
%               window radius used (w).
%
%
% Output Parameters
%
%   ZIfin       A digital surface model (DSM) of the ground.  If an
%               elevation threshold is not provided, the final DSM is set 
%               equal to the prospective DSM (see below).
%
%   R           A referencing matrix that relates the image file (ZIfin) to
%               map coordinates.  See worldfileread for more information.
%   
%   isObject    A logical vector, equal in length to (x,y,z), that
%               describes whether each tuple is ground (0) or nonground (1)
%
%   ZIpro       The prospective ground surface created after the smrf
%               algorithm has identified nonground cells in the initial
%               minimum surface (ZImin).  It is created by inpainting all 
%               empty, outlier, or nonground cells from the minimum 
%               surface.
%
%   ZImin       The initial minimum surface after smrf internally calls
%               createDSM.m.
%
%   isObjectCell 
%               Cells in ZImin that were classified as empty,outliers,or
%               objects during SMRF's run.
%
% Examples
% 
% % Test SMRF against ISPRS data set.
% 
% % Download reference LIDAR data
% url = 'http://www.itc.nl/isprswgIII-3/filtertest/Reference.zip';
% fn = 'Reference.zip';
% urlwrite(url,[tempdir,'\',fn]);
% unzip([tempdir,'\',fn], tempdir);
% 
% % Read data
% M = dlmread([tempdir,'\samp11.txt']);
% x = M(:,1);
% y = M(:,2);
% z = M(:,3);
% gobs = M(:,4);  % 0 is Ground, 1 is Object
% clear M;
% 
% % Declare parameters for this sample (Pingel et al., 2011)
% c = 1;
% s = .2;
% w = 16;
% et = .45;
% es = 1.2;
% 
% % Run filter
% [ZI R gest] = smrf(x,y,z,'c',c,'s',s,'w',w,'et',et,'es',es);
% 
% % Report results
% ct = crosstab(gobs,gest)
% 
% % View surface
% figure;
% surf(ZI,'edgecolor','none'); axis equal vis3d
%
% References:   The filter was succesfully tested against the Sithole and
%               Vosselman's (2003) ISPRS LIDAR Dataset
%               (http://www.itc.nl/isprswgIII-3/filtertest/).
%
%
%%
%
% Author:
%   Thomas J. Pingel
%   Department of Geography
%   University of California, Santa Barbara
%   pingel@geog.ucsb.edu
%
%
%
% License
% Copyright (c) 2011, Thomas J. Pingel
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without 
% modification, are permitted provided that the following conditions are 
% met:
% 
%     * Redistributions of source code must retain the above copyright 
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright 
%       notice, this list of conditions and the following disclaimer in 
%       the documentation and/or other materials provided with the distribution
%       
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
% POSSIBILITY OF SUCH DAMAGE.
%
%
% See Also:
% worldfilewrite.m, 



function [ZIfin R isObject ZIpro ZImin isObjectCell] = smrf(x,y,z,varargin)

if nargin < 9
    error('Not enough arguments.  Minimum call: smrf(x,y,z,''c'',c,''s'',s,''w'',w)');
end

dependencyCheck = [exist('consolidator') exist('inpaint_nans')];
if any(dependencyCheck==0)
    disp('The smrf algorithm requires that consolidator.m and inpaint_nans.m are accessible.');
    disp('Both of these functions were written by John D''Errico and are available through the');
    disp('Mathworks file exchange.');
    disp('consolidator is located at http://www.mathworks.com/matlabcentral/fileexchange/8354');
    disp('inpaint_nans is located at http://mathworks.com/matlabcentral/fileexchange/4551');
    error('Please acquire these files before attempting to run smrf again.');
end
% Initialize possible input values
cellSize = [];
slopeThreshold = [];
wkmax = [];
xi = [];
yi = [];
elevationThreshold = [];
elevationScaler = [];

% Initialize output values
ZIfin = [];
R = [];
isObject = [];

% Declare other global variables
inpaintMethod = 4;  % Springs
cutNetSize = [];
isNetCell = [];


%% Process extra arguments

i = 1;
while i<=length(varargin)    
    if isstr(varargin{i})
        switchstr = lower(varargin{i});
        switch switchstr
            case 'c' % Cell size (required, or xi and yi must be supplied)
                cellSize = varargin{i+1};
                i = i + 2;
            case 's' % Slope tolerance (required)
                slopeThreshold = varargin{i+1};
                i = i + 2;
            case 'w' % Maximum window size, in map units (required)
                wkmax = varargin{i+1};
                i = i + 2;  
            case 'et'   % Elevation Threshold (optional)
                elevationThreshold = varargin{i+1};
                i = i + 2;
            case 'es'   % Elevation Scaling Factor (optional)
                elevationScaler = varargin{i+1};
                i = i + 2;
            case 'xi'   % A supplied vector for x
                xi = varargin{i+1};
                i = i + 2;
            case 'yi'   % A supplied vector for y
                yi = varargin{i+1};
                i = i + 2;        
            case 'inpaintmethod'  % Argument to pass to inpaint_nans.m
                inpaintMethod = varargin{i+1};
                i = i + 2;
            case 'cutnet'   % Support to a cut a grid into large datasets
                cutNetSize = varargin{i+1};
                i = i + 2;
            case 'objectMask'
                objectMask = varargin{i+1};
                i = i + 2;
            otherwise
                i = i + 1;
        end
    else
        i = i + 1;
    end
end    


%% Check for a few error conditions

if isempty(slopeThreshold)
    error('Slope threshold must be supplied.');
end

if isempty(wkmax)
    error('Maximum window size must be supplied.');
end

if isempty(cellSize) && isempty(xi) && isempty(yi)
    error('Cell size or (xi AND yi) must be supplied.');
end

if isempty(xi) && ~isempty(yi)
    error('If yi is defined, xi must also be defined.');
end

if ~isempty(xi) && isempty(yi)
    error('If xi is defined, yi must also be defined.');
end

if ~isempty(xi) && ~isvector(xi)
    error('xi must be a vector');
end

if ~isempty(yi) && ~isvector(yi)
    error('yi must be a vector');
end

if ~isempty(xi) && (abs(xi(2) - xi(1)) ~= abs(yi(2) - yi(1)))
    error('xi and yi must be incremented identically');
end

if isempty(cellSize) && ~isempty(xi) && ~isempty(yi)
    cellSize = abs(xi(2) - xi(1));
end

if ~isempty(elevationThreshold) && isempty(elevationScaler)
    elevationScaler = 0;
end

%% Create Digital Surface Model
if isempty(xi)
    [ZImin R isEmptyCell xi yi] = createDSM(x,y,z,'c',cellSize,'type','min','inpaintMethod',inpaintMethod);
else
    [ZImin R isEmptyCell] = createDSM(x,y,z,'xi',xi,'yi',yi,'type','min','inpaintMethod',inpaintMethod);
end

%% Detect outliers

[isLowOutlierCell] = progressiveFilter(-ZImin,'c',cellSize,'s',5,'w',1); 

%% Cut a mesh into Zmin, if desired
if ~isempty(cutNetSize)
    [ZInet isNetCell] = createNet(ZImin,cellSize,cutNetSize);
else
    ZInet = ZImin;
    isNetCell = logical(zeros(size(ZImin)));
end

%% Detect objects

[isObjectCell] = progressiveFilter(ZInet,'c',cellSize,'s',slopeThreshold,'w',wkmax); 

%% Construct a prospective ground surface

ZIpro = ZImin;
ZIpro(isEmptyCell | isLowOutlierCell | isObjectCell | isNetCell) = NaN;
ZIpro = inpaint_nans(ZIpro,inpaintMethod);
isObjectCell = isEmptyCell | isLowOutlierCell | isObjectCell | isNetCell;


%% Identify ground ...
% based on elevationThreshold and elevationScaler, if provided

if ~isempty(elevationThreshold) && ~isempty(elevationScaler)

    % Identify Objects
        % Calculate slope
    [gx gy] = gradient(ZIpro / cellSize);
    gsurfs = sqrt(gx.^2 + gy.^2); % Slope of final estimated ground surface
    clear gx gy
            
    % Get Zpro height and slope at each x,y point
    iType = 'spline';
    [r c] = map2pix(R,x,y);
    ez = interp2(ZIpro,c,r,iType);
    SI = interp2(gsurfs,c,r,iType);
    clear r c

    requiredValue = elevationThreshold + (elevationScaler * SI);
    isObject = abs(ez-z) > requiredValue;
    clear ez SI requiredValue 
    
    
    % Interpolate final ZI
   F = TriScatteredInterp(x(~isObject),y(~isObject),z(~isObject),'natural');
   [XI,YI] = meshgrid(xi,yi);
   ZIfin = F(XI,YI);
else
   warning('Since elevation threshold and elevation scaling factor were not provided for ground identification, ZIfin is equal to ZIpro.');
   ZIfin = ZIpro;
end



end  % Function end