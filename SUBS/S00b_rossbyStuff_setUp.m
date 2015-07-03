function [TS]=S00b_rossbyStuff_setUp(DD)   
    %% temp salt keys
    TS = getTempSaltFiles(tempSaltKeys);    
    TS.keys = mergeStruct2(DD.FieldKeys.Rossby,TS.keys);
    %% get window according to user input
    TS.map = DD.map.in;
    TS.map.keys = TS.keys;
    [TS.window,~] = GetWindow3(TS.salt{1},TS.map);
    %% distro X lims to chunks
   TS.lims.chunks = limsdata(TS.numChunks, TS.window);
    %% distro chunks to threads
    TS.lims.threads = thread_distro(DD.threads.num,TS.numChunks);
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