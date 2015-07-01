%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 19-Jun-2014 19:32:07
% Computer:  GLNXA64
% Matlab:  8.1
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [out]=ZonalProblem(in,window)
    %% full globe?
     seam=true;
    if strcmp(window.type,'globe')
        [y,x]=AppendIfFullZonal(window);% longitude edge crossing has to be addressed
    else
        [y,x,seam]=nonXContinuousCase(window);
    end
    %%
    out=buildGrids(in,y,x,window,seam);    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [y,x,seam]=nonXContinuousCase(w)
    %% seam crossing?
    if strcmp(w.type,'zonCross') % ie not full globe but both seam ends are within desired window
        [y,x]=SeamCross(in,w);
    else % desired piece is within global fields, not need for stitching
        seam=false;
        [y,x]=AllGood(w);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [y,x]=AppendIfFullZonal(w)
    %% append 1/10 of map to include eddies on seam
    % S04_track_eddies is able to avoid counting 1 eddy twice   
    xadd=round(w.dim.X/10);
    [x,y]=meshgrid([1:w.dim.X, 1:xadd],w.limits.south:w.limits.north);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [y,x]=SeamCross(w)
    %% stitch 2 pieces 2g4
    [x,y]=meshgrid([w.limits.west:w.dim.X, 1:w.limits.east],w.limits.south:w.limits.north);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [y,x]=AllGood(w)
    %% clear cut
    [x,y]=meshgrid(w.limits.west:w.limits.east,w.limits.south:w.limits.north);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out=buildGrids(in,y,x,window,seam)
    xlin=drop_2d_to_1d(y,x,window.fullsize(1));
    %% cut piece
    fields=fieldnames(in);
    for field=fields';ff=field{1};        
        out.grids.(ff) =in.(ff)(xlin);
    end
    %% append params
    out.window = window;
    out.params.seam = seam;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%