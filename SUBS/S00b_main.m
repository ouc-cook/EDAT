%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 04-Sep-2014 16:53:06
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sub to ../S00b_prep..
function S00b_main(DD,II)
    [T]=disp_progress('init','preparing raw data');
    for cc=1:numel(II);
        [T]=disp_progress('calc',T,numel(II),100);
        %% get data
        [file,exists]=GetCurrentFile(II(cc),DD)  ;
        %% skip if exists and ~overwrite switch
        if exists.out && ~DD.overwrite;
            disp('exists');continue
        end
        %% cut data
        [CUT]=CutMap(file,DD);
        %% save empty corrupt files too
        if isfield(CUT,'crpt');
            [d,f,x] = fileparts(file.out ) ;
            file.out = fullfile(d,['CORRUPT-' f x]);
        end
        %% write data
        WriteFileOut(file.out,CUT);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [CUT]=CutMap(file,DD)
    %% get data
    for kk={'ssh'}
        keys.(kk{1})=DD.map.in.keys.(kk{1});
    end
    
    [raw_fields,unreadable]=GetFields(file.in,keys);
    if unreadable.is, CUT.crpt=true; return; end
    %% cut
    [CUT.fields]=cutSlice(raw_fields,DD.map.window);
    %% nan out land and make SI
    CUT.fields.ssh=nanLand(CUT.fields.ssh,DD.parameters.ssh_unitFactor);
    %% get distance fields
%     [CUT.fields.dy,CUT.fields.dx]=dydx(CUT.fields.lat,CUT.fields.lon);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out=nanLand(in,fac)
    %% nan and SI
    out=in / fac;
    out(out==0)=nan;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%=========================================================================%
function WriteFileOut(file,CUT) %#ok<INUSD>
    save(file,'-struct','CUT')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [file,exists]=GetCurrentFile(TT,DD)
    exists.out=false;
    file.in=TT.files;
    timestr=datestr(TT.daynums,'yyyymmdd');
    %% set up output file
    path=DD.path.cuts.name;
    geo=DD.map.in;
    file.out=NSWE2nums(path,DD.pattern.fname,geo,timestr);
    if exist(file.out,'file')
        disp([file.out ' exists']);
        disp(['checking for corruptness']);
        exists.out = true;
        try
            load(file.out,'-mat','fields')
        catch
            disp([file.out ' corrupt!']);
            system(['rm ' file.out]);
            
            %% TODO
            eddy = strrep(file.out,'CUT','EDDIE');
            try
                system(['rm ' eddy]);
            catch nohave
                disp([nohave.message]) ;
            end
            
            cont = strrep(file.out,'CUT','CONT');
            try
                system(['rm ' cont]);
            catch nohave
                disp([nohave.message]) ;
            end
            %%
            
            exists.out = false;
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


