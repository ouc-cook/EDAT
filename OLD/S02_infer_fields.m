%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 04 - Apr - 2014 16:53:06
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculates geostrophic data from ssh
% theoretically NEEDS FULL RE RUN IF DATES ARE CHANGED !!!!(meanSSH)
function S02_infer_fields
    %% init
    DD = initialise('cuts',mfilename);
    %% read input file
    DD.map.window = getfieldload(DD.path.windowFile,'window');
    DD.coriolis = coriolisStuff(DD.map.window.lat);
    RS = getRossbyStuff(DD);
    %% spmd
    main(DD,RS)
    %% save info file
    %     conclude(DD)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD,RS)
    %% infer mean ssh
    spmd(DD.threads.num)
        [JJ] = SetThreadVar(DD);
        spmd_meanSsh(DD,JJ);
    end
    %     %
    MeanSsh = saveMean(DD);
    %         MeanSsh = getfield(load([DD.path.root, 'meanSSH.mat']),'MeanSsh');
    %%
    spmd(DD.threads.num)
        [JJ] = SetThreadVar(DD);
        spmd_fields(DD,RS,JJ,MeanSsh);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function MeanSsh = saveMean(DD)
    MeanSsh = nan(DD.map.window.dimPlus.y * DD.map.window.dimPlus.x,1);
    Meancount = 0;
    for ll = 1:DD.threads.num
        cur = load(sprintf('meanTmp%03d.mat',ll));
        MeanSsh = nansum([MeanSsh cur.Mean.SshSum],2);
        Meancount = Meancount + cur.Mean.count;
        system(sprintf('rm meanTmp%03d.mat',ll));
    end
    MeanSsh = reshape(MeanSsh,[DD.map.window.dimPlus.y, DD.map.window.dimPlus.x])/Meancount;
    save([DD.path.root, 'meanSSH.mat'],'MeanSsh')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RS = getRossbyStuff(DD)
    if DD.switchs.RossbyStuff
        RS.Lr = getfield(load([DD.path.Rossby.name DD.FieldKeys.Rossby{1} '.mat']),'data');
        RS.c = getfield(load([DD.path.Rossby.name DD.FieldKeys.Rossby{2}  '.mat']),'data');
    else
        RS = [];
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function spmd_meanSsh(DD,JJ)
    T = disp_progress('init','infering mean ssh');
    Mean.SshSum = nan(DD.map.window.dimPlus.y * DD.map.window.dimPlus.x,1);
    for jj = 1:numel(JJ)
        T = disp_progress('disp',T,numel(JJ),100);
        %% load
        cut=getfield(load(JJ(jj).files),'fields');
        if isfield(cut,'sshRaw')
            ssh = extractdeepfield(cut,'sshRaw')';
        else
            ssh = extractdeepfield(cut,'ssh')';
        end
        %% mean ssh
        Mean.SshSum = nansum([Mean.SshSum, ssh],2);
    end
    Mean.count = numel(JJ);
    save(sprintf('meanTmp%03d.mat',labindex),'Mean');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function spmd_fields(DD,RS,JJ,MeanSsh)
    T = disp_progress('init','infering fields');
    for jj = 1:numel(JJ)
        T = disp_progress('disp',T,numel(JJ),100);
        
        %         %% TODO
        %         if getfield(dir(JJ(jj).files),'bytes')/1e6 > 300
        %             continue
        %         end
        %%
        
        cut = load(JJ(jj).files);
        %% filter
        if DD.switchs.filterSSHinTime
            %% already built
            if isfield(cut.fields,'sshRaw')
                %                 continue
                cut.fields.ssh = cut.fields.sshRaw;
            end
            %% TODO
            %             eddy = strrep(JJ(jj).files,'CUT','EDDIE');
            %             try
            %                 system(['rm ' eddy]);
            %             catch nohave
            %                 disp([nohave.message]) ;
            %             end
            %
            %             cont = strrep(JJ(jj).files,'CUT','CONT');
            %             try
            %                 system(['rm ' cont]);
            %             catch nohave
            %                 disp([nohave.message]) ;
            %             end
            %%
            cut.fields.sshRaw = cut.fields.ssh;
            %% filter
            cut.fields.ssh = cut.fields.ssh - MeanSsh;
        end
        %%
        coriolis = coriolisStuff(DD.map.window.lat);
        %% calc
        fields = geostrophy(DD.map.window,cut.fields,coriolis,RS); %#ok<NASGU>
        %% write      
        save(JJ(jj).files,'fields','-append');
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gr = geostrophy(win,gr,corio,RS)
    %% ssh gradient
    [gr.sshgrad_x,gr.sshgrad_y] = dsshdxi(gr.ssh,win.dx,win.dy);
    %% velocities
    gr.U = - corio.GOverF.*gr.sshgrad_y;
    gr.V = corio.GOverF.*gr.sshgrad_x;
    gr.absUV = hypot(abs(gr.U),abs(gr.V));
    %% 2d - deformation
    %     def = deformation(gr);
    %     gr.vorticity = def.dVdx - def.dUdy;
    %     gr.divergence = def.dUdx + def.dVdy;
    %     gr.stretch = def.dUdx - def.dVdy;
    %     gr.shear = def.dVdx + def.dUdy;
    %% okubo weiss
    %     gr.OW = .5*( - gr.vorticity.*2 + gr.divergence.*2 + gr.stretch.*2 + gr.shear.*2);
    %% or in 2d
    %     gr.OW = 2*(def.dVdx.*def.dUdy + def.dUdx.^2);
    %% assuming Ro = 1
    if ~isempty(RS)
        gr.L = gr.absUV./corio.f;
        %         kinVis = 1e-6;
        %         gr.Re = gr.absUV.*gr.L/kinVis;
        %         gr.Ro = ones(size(gr.L));
        %         gr.Rrhines = earthRadius./gr.L;
        %         gr.Lrhines = sqrt(gr.absUV./corio.beta);
        %         gr.L_R = abs(RS.c./corio.f);
        %         gr.Bu = (gr.L_R./gr.L).^2;
    end
    % TODO build switches at top which ones to save
    gr = rmfield(gr,{'sshgrad_x','sshgrad_y','U','V','absUV'});
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function def = deformation(fields)
    %% calc U gradients
    dUdy = diff(fields.U,1,1);
    dUdx = diff(fields.U,1,2);
    dVdy = diff(fields.V,1,1);
    dVdx = diff(fields.V,1,2);
    def.dUdy = dUdy([1:end, end], :)  ./ fields.dy;
    def.dUdx = dUdx(:,[1:end, end] )  ./ fields.dx;
    def.dVdy = dVdy([1:end, end], :)  ./ fields.dy;
    def.dVdx = dVdx(:,[1:end, end] )  ./ fields.dx;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [dsshdx,dsshdy] = dsshdxi(ssh,dx,dy)
    %% calc ssh gradients
    dsshdx = diff(ssh,1,2);
    dsshdy = diff(ssh,1,1);
    dsshdx = dsshdx(:,[1:end, end])./ dx;
    dsshdy = dsshdy([1:end, end],:)./ dy;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = coriolisStuff(lat)
    %% omega
    out.Omega = angularFreqEarth;
    %% f
    out.f = 2*out.Omega*sind(lat);
    %% beta
    out.beta = 2*out.Omega/earthRadius*cosd(lat);
    %% gravity
    out.g = sw_g(lat,zeros(size(lat)));
    %% g/f
    out.GOverF = out.g./out.f;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
