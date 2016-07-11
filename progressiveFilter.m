% progressiveFilter
%   Removes high points from a Digital Surface Model by progressive
%   morphological filtering.
%
% Syntax
%   function [isObjectCell] = progressiveFilter(ZI,varargin)
%
%
% Description
%   The progressive morphological filter is the heart of the SMRF lidar
%   ground filtering package.  Given an image, a cellsize, a slope
%   threshold, and a maximum window size, the filter uses an image opening
%   operation of iteratively increasing size to locate all "objects" - high
%   points in the image like trees or buildings.
%
%   The progressiveFilter must be minimally called with an image (a digital 
%   surface model) as well as a cellsize (c), a slope threshold value (s), 
%   and a maximum window size (w).  The slope threshold value governs the
%   identification process, and roughly corresponds to the maximum slope of
%   the terrain you are working with.  The maximum window size defines a
%   window radius (in map units), and corresponds to the size of largest 
%   feature to be removed.
%
%
% Requirements
%   Image Processing Toolbox
%   progressiveFilter requires John D'Errico's inpaint_nans.m file.
%   http://mathworks.com/matlabcentral/fileexchange/4551
%
%
% Input Parameters
%   ZI        - A digital surface model, preferably a minimum surface
%
%   'c',c     - Cell size, in map units
%
%   's',s     - Defines the maximum expected slope of the ground surface
%               Values are given in dz/dx, so most slope values will be in
%               the range of .05 to .30.
%
%   'w',w     - Defines the filter's maximum window radius.  
%   'w',[0 w]   Alternatively, the user can supply his or her own vector of
%   'w',[1:5:w] window sizes to control the open process.  
%
%   'inpaintMethod',ipm
%               If this parameter is supplied, it controls the argument
%               passed to D'Errico's inpaint_nans method.  The default
%               value is 4.
%
%   'cutNet',netSize
%               Cuts a net of spacing netSize (map coordinates) into ZI
%               before further processing.  This can help to remove large
%               buildings without the need for extremely large filter
%               windows.  Generally, netSize should be set to the largest
%               window radius used (w).
%
%
% Output Parameters
%
%   isObjectCell
%               A logical image mask indicating cells flagged as objects.
%
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
    


function [isObjectCell lastSurface thisSurface] = progressiveFilter(lastSurface,varargin)

% Define required input parameters
cellSize = [];
slopeThreshold = [];
wkmax = [];

% Define optional input parameters
inpaintMethod = [];
strelShape = [];

% Define output parameters
isObjectCell = [];


%% Process supplied arguments

i = 1;
while i<=length(varargin)    
    if isstr(varargin{i})
        switchstr = lower(varargin{i});
        switch switchstr
            case 'c'
                cellSize = varargin{i+1};
                i = i + 2;
            case 's'
                slopeThreshold = varargin{i+1};
                i = i + 2;
            case 'w'
                wkmax = varargin{i+1};
                i = i + 2;  
            case 'inpaintmethod'
                inpaintMethod = varargin{i+1};
                i = i + 2;
            case 'shape'
                strelShape = varargin{i+1};
                i = i + 2;
            otherwise
                i = i + 1;
        end
    else
        i = i + 1;
    end
end


%% Catch some errors

if isempty(cellSize)
    error('Cell size must be specified.');
end
if isempty(wkmax)
    error('Maximum window size must be specified');
end
if isempty(slopeThreshold)
    error('Slope threshold value must be specified.');
end


%% Define some default parameters

if isempty(inpaintMethod)
    inpaintMethod = 4; % Springs
end

if isempty(strelShape)
    strelShape = 'disk';
end


%% Convert wkmax to a vector of window sizes (radii) defined in pixels.  
% If w was supplied as a vector, use those values as the basis; otherwise,
% use 1:1:wkmax

if numel(wkmax)~=1
    wk = ceil(wkmax / cellSize);
else
    wk = 1 : ceil(wkmax / cellSize);
end

% wk = wkmax;
%% Define elevation thresholds based on supplied slope tolerance

eThresh = slopeThreshold * (wk * cellSize);


%% Perform iterative filtering.

isObjectCell = logical(zeros(size(lastSurface)));

for i = 1:length(wk)
    thisSurface = imopen(lastSurface,strel(strelShape,wk(i)));
    isObjectCell = isObjectCell | (lastSurface - thisSurface > eThresh(i));
    lastSurface = thisSurface;
end

