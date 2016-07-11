% createNet
% Simple utility to cut a "net" of background values into a digital surface model
%
% Syntax
%   [ZInet isNetCell] = createNet(ZI,cellSize,netWidth)
%
%
% Description
%   createNet removes columns and rows from ZI according to the spacing
%   specified in gridSpacing, which is a spacing specified according to
%   map coordinates (not necessarily pixels).  These columns and rows are
%   refilled according to background values calculated from an image
%   opening operation with a disk-shaped structuring element with a radius
%   twice the size of netWidth.  Cutting in a net into a DSM helps to keep
%   the size of the filter window to a manageable size.  A net is typically
%   useful when the buildings can not be entirely removed with a 20 meter
%   window radius.
%
%
% Requirements
%   Image Processing Toolbox
%
%
% Input Parameters
%   ZI           - A two dimensional image
%
%   cellSize     - The spacing (in map units) between cells
%
%   netWidth     - The size (in map units) for the net
%
%
% Output Parameters
%
%   ZInet        - ZI, with the net cut in 
%
%   isNetCell    - A logical image mask of the net
%
%
%
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



function [ZInet isNetCell] = createNet(ZImin,cellSize,gridSize)

    bigOpen = imopen(ZImin,strel('disk',2*ceil(gridSize/cellSize)));
    isNetCell = logical(zeros(size(ZImin)));
    isNetCell(:,1:ceil(gridSize/cellSize):end) = 1;
    isNetCell(1:ceil(gridSize/cellSize):end,:) = 1;
    
    ZInet = ZImin;
    ZInet(isNetCell) = bigOpen(isNetCell);
    