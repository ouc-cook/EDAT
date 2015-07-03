
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 15-Jul-2014 13:52:44
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [TS]=S00b_rossbyStuff_setUp(DD)   
    %% temp salt keys
    TS = getTempSaltFiles(tempSaltKeys);
    %% get window according to user input
    TS.map = DD.map.in;
    TS.map.keys = TS.keys;
    [TS.window,~] = GetWindow3(TS.salt{1},TS.map);
    %% distro X lims to chunks
   TS.lims.dataIn = limsdata(TS.chunks,TS.window);
    %% distro chunks to threads
    TS.lims.loop = thread_distro(DD.threads.num,TS.chunks);
end

function TS = tempSaltKeys
    TS.dir = '/scratch/uni/ifmto/u300065/TempSaltUV/';
    TS.keys.lat = 'U_LAT_2D';
    TS.keys.lon = 'U_LON_2D';
    TS.keys.salt = 'SALT';
    TS.keys.temp = 'TEMP';
    TS.keys.depth = 'depth_t';
    %%
    TS.files = dir2([TS.dir,'*.nc']);
    TS.chunks = 28; % number of chunks for brunt väis calculations
    TS.salinityFactor = 1000;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lims=limsdata(splits,window)
    %% set dimension for splitting (files dont fit in memory)
    X = window.dimPlus.x;
    %% distro X lims to chunks
    lims = thread_distro(splits,X) + window.limits.west-1;
    %% in case window crosses zonal bndry
    beyondX = lims>window.fullsize.x;
    lims(beyondX) = lims(beyondX) - window.fullsize.x;
    %% in case one chunk crosses zonal bndry
    td=lims(:,2)-lims(:,1) < 1; % find chunk
    lims(td,1)=1; % let it start at 1
    lims(find(td)-1,2)=window.fullsize.x; % let the one before finish at end(X)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% somewhat redundant since we only use one temp/salt file each..
function TS = getTempSaltFiles(TS)
    %% find the temp and salt files
    tt=0;ss=0;
    checkForfield = @(field,file) ~isempty(strfind(upper(file),field));
    %%
    for kk=1:numel(TS.files);
        currFile = TS.files(kk);
        if checkForfield('SALT',currFile.name)
            ss = ss+1;
            TS.salt{ss} = currFile.fullname;
        elseif checkForfield('TEMP',currFile.name)
            tt = tt+1;
            TS.temp{tt} = currFile.fullname;
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%