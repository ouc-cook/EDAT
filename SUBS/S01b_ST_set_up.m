
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 15-Jul-2014 13:52:44
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [DD]=S01b_ST_set_up
    %% init
    DD=initialise([],mfilename);
    %% threads
    DD.threads.num=init_threads(DD.threads.num);
    %% find temp and salt files
    [DD.path.TempSalt]=tempsalt(DD);
    %% get window according to user input
    TSmap=DD.map.in;
    TSmap.keys=DD.TS.keys;
    [DD.TS.window,~]=GetWindow3(DD.path.TempSalt.salt{1},TSmap);
    %% distro X lims to chunks
    DD.RossbyStuff.lims.dataIn=limsdata(DD.parameters.RossbySplits,DD.TS.window);
    %% distro chunks to threads
    DD.RossbyStuff.lims.loop=thread_distro(DD.threads.num,DD.parameters.RossbySplits);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lims=limsdata(splits,window)
    %% set dimension for splitting (files dont fit in memory)
    X=window.dimPlus.x;
    %% distro X lims to chunks
    lims=thread_distro(splits,X) + window.limits.west-1;
    %% in case window crosses zonal bndry
    beyondX = lims>window.fullsize.x; 
    lims(beyondX) = lims(beyondX) - window.fullsize.x;
    %% in case one chunk crosses zonal bndry
    td=lims(:,2)-lims(:,1) < 1; % find chunk
    lims(td,1)=1; % let it start at 1
    lims(find(td)-1,2)=window.fullsize.x; % let the one before finish at end(X)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [file]=tempsalt(DD)
    %% find the temp and salt files
	 tt=0;ss=0;
    for kk=1:numel(DD.path.TempSalt.files);
        if ~isempty(strfind(upper(DD.path.TempSalt.files(kk).name),'SALT'))
			  ss=ss+1; 
            file.salt{ss}=[DD.path.TempSalt.name DD.path.TempSalt.files(kk).name];
        end
        if ~isempty(strfind(upper(DD.path.TempSalt.files(kk).name),'TEMP'))
			   tt=tt+1;
            file.temp{tt}=[DD.path.TempSalt.name DD.path.TempSalt.files(kk).name];
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%