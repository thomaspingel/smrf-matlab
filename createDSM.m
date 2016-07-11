% createDSM
% Simple utility to construct a Digital Surface Model from LIDAR data.
%
%
% Syntax
%   [DSM R isEmptyCell xi yi] = createDSM(x,y,z,varargin);
%
%
% Description
%   createDSM takes as input a three dimensional point cloud (usually LIDAR
%   data) and creates an initial ground surface, useful for further
%   processing routes that can extract ground and identify objects in
%   scene.  Required input (in addition to the point cloud) is a cellSize
%   (in map coordinates).  The user may, instead, optionally specify xi and
%   yi, two vectors to which the data will are then snapped.  By default
%   createDSM creates a minimum surface, in which duplicate cell values are
%   reduced to their minimum.  However, the user may specify other values
%   (e.g., 'mean', 'max') if desired.
%
%
% Requirements
%   Requires John D'Errico's consolidator.m and inpaint_nans.m files.
%   These are available via the Mathworks File Exchange Program at:
%   http://www.mathworks.com/matlabcentral/fileexchange/8354
%   http://mathworks.com/matlabcentral/fileexchange/4551
%
%   Also requires that the Mathworks Mapping Toolbox is installed.
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
%   'type',t    String value or function handle specifying the basis for
%               consolidation.  Possible values include 'min', 'median',
%               'mean', 'max'.  See consolidator.m for all possible inputs.
%
%   'inpaintMethod',ipm
%               If this parameter is supplied, it controls the argument
%               passed to D'Errico's inpaint_nans method.  The default
%               value is 4.
%
%
% Output Parameters
%
%   DSM         A digital surface model (DSM) of the ground. 
%
%   R           A referencing matrix that relates the image file (ZIfin) to
%               map coordinates.  See worldfileread for more information.
%   
%   isEmptyCell An image mask describing whether the DSM was empty or not
%               at that location.  
%
%   xi,yi       Vectors describing the range of the image.
%
%
% Examples:
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
% % Create a minimum surface
% [ZImin R isEmptyCell] = createDSM(x,y,z,'c',1,'min');
% 
% % Write data to geotiff
% imwrite(ZImin,'samp11.tif','tif');
% worldfilewrite(R,'samp11.tfw');
%
%
% Author:
%   Thomas J. Pingel
%   Department of Geography
%   University of California, Santa Barbara
%   pingel@geog.ucsb.edu
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
% See Also:
% worldfilewrite.m, 

function [DSM,R,isEmptyCell xi yi] = createDSM(x,y,z,varargin)

% Define inputs

cellSize = [];
inpaintMethod = [];
xi = [];
yi = [];
cType = [];

% Define outputs

DSM = [];
R = [];
isEmptyCell = [];

%% Process supplied arguments

i = 1;
while i<=length(varargin)    
    if isstr(varargin{i})
        switchstr = lower(varargin{i});
        switch switchstr
            case 'c'
                cellSize = varargin{i+1};
                i = i + 2;
            case 'inpaintmethod'
                inpaintMethod = varargin{i+1};
                i = i + 2;
            case 'xi'
                xi = varargin{i+1};
                i = i + 2;
            case 'yi'
                yi = varargin{i+1};
                i = i + 2;
            case 'type'
                cType = varargin{i+1};
                i = i + 2;
            otherwise
                i = i + 1;
        end
    else
        i = i + 1;
    end
end    


    if isempty(cType)
        cType = 'min';
    end
    if isempty(inpaintMethod)
        inpaintMethod = 4; % Springs as default method
    end

    % define cellsize from xi and yi if they were not defined
    if ~isempty(xi) & ~isempty(yi)
        cellSize = abs(xi(2) - xi(1));
    end
    
    if isempty(cellSize)
        error('Cell size must be declared.');
    end
    
    % Define xi and yi if they were not supplied
    if isempty(xi) & isempty(yi)
        xi = ceil2(min(x),cellSize):cellSize:floor2(max(x),cellSize);
        yi = floor2(max(y),cellSize):-cellSize:ceil2(min(y),cellSize);
    end

    % Define meshgrids and referencing matrix
    [XI YI] = meshgrid(xi,yi);
    R = makerefmat(xi(1),yi(1),xi(2) - xi(1),yi(2) - yi(1));

    % Create gridded values
    xs = round3(x,xi);
    ys = round3(y,yi);

    % Translate (xr,yr) to pixels (r,c)
    [r c] = map2pix(R,xs,ys);
    r = round(r);  % Fix any numerical irregularities
    c = round(c);  % Fix any numerical irregularities
    %  Translate pixels to single vector of indexed values
    idx = sub2ind([length(yi) length(xi)],r,c);
    
    % Consolidate those values according to minimum
    [xcon Z] = consolidator(idx,z,cType);

    % Remove any NaN entries.  How these get there, I'm not sure.
    Z(isnan(xcon)) = [];
    xcon(isnan(xcon)) = [];
    
    % Construct image
    DSM = nan(length(yi),length(xi));
    DSM(xcon) = Z;
    
    isEmptyCell = logical(isnan(DSM));
    
    % Inpaint NaNs
    if (inpaintMethod~=-1 & any(isnan(DSM(:))))
        DSM = inpaint_nans(DSM,inpaintMethod);
    end
    
%     tStop = tStart - tStop;

end




function xr2 = floor2(x,xint)
    xr2 = floor(x/xint)*xint;
end

function xr2 = ceil2(x,xint)
    xr2 = ceil(x/xint)*xint;
end

function xs = round3(x,xi) % Snap vector of x to vector xi
    dx = abs(xi(2) - xi(1));
    minxi = min(xi);
    maxxi = max(xi);

    %% Perform rounding on interval dx
    xs = (dx * round((x - minxi)/dx)) + minxi;

    %% Outside the range of xi is marked NaN
    % Fix edge cases
    xs((xs==minxi-dx) & (x > (minxi - (dx)))) = minxi;
    xs((xs==maxxi+dx) & (x < (maxxi + (dx)))) = maxxi;
    % Make NaNs
    xs(xs < minxi) = NaN;
    xs(xs > maxxi) = NaN;
end