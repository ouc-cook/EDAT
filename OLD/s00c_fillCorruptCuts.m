%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 04-Apr-2014 16:53:06
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pop data has some corrupt netcdf's. this is intended to fill gaps in case
% of large time-steps only. eg take data from day 6 instead of day 7. or 8
% or 5 or 9... and use it as day 7 data. hence avoid 14 day gaps
function s00c_fillCorruptCuts
    %% init
    DD=initialise('raw',mfilename);
    DD=init(DD);
    %%
    tshift=[-1 1 -2 2];
    %%
    scanforcorrupts(DD,tshift)
    %%
    conclude(DD);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [broke]=getRawFromTshift(DD,tshif)
    broke=false;
    tmp=dir([DD.path.cuts.name '*CORRUPT*CUT*']);
    %%
    if isempty(tmp)
        broke=true;
        disp('no more corrupt cuts!!!')
        return
    end
    %%
    file(numel(tmp))=struct;
    [file(:).corr]=deal(tmp.name);
    
    %% dist corrupt files to II
    for ff=1:numel(file)
        when.str=file(ff).corr(13:13+7)    ;
        when.num=datenum(when.str,'yyyymmdd');
        when.newNum=when.num + tshif;
        when.Newstr= datestr(when.newNum,'yyyymmdd');
        file(ff).cut = [file(ff).corr(9:12) when.str file(ff).corr(13+7+1:end)];
        file(ff).raw = strrep(DD.map.in.fname, 'yyyymmdd',when.Newstr);
        II(ff).files = [DD.path.raw.name  file(ff).raw ] ;
        II(ff).daynums = when.newNum;
%         warning(['will try to get data for ' when.str ' from ' when.Newstr ' instead!'])
        %%
        system(['rm ' DD.path.cuts.name  file(ff).corr]);
        try
            system(['rm ' DD.path.cuts.name  file(ff).cut]);
        end
        %%
    end
    %% loop over files
    S00b_main(DD,II);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function scanforcorrupts(DD,tshift)
    corruptsexist=true;
    while corruptsexist
        for ii=1:numel(tshift)
            corruptsexist=~getRawFromTshift(DD,tshift(ii));
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DD=init(DD)
    tmp=load([DD.path.root, 'window.mat']);
    for wf=fieldnames(tmp.window)'
        DD.map.window.(wf{1})=tmp.window.(wf{1});
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%















