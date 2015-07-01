function OverSall
   
    initialise
    sleep(60)
    DR='/scratch/uni/ifmto/u300065/FINAL/smAor/';
    Fnows={'iq2';'iq6';'iq6dl';'iq6dlMr';'iq6dlMrIc';'iq8';'iq4';'ch'};
    Dnows=cellfun(@(c) ['data' c],Fnows,'uniformoutput',false);
    
    dbstop if error
    Rdata=[DR 'dataC/'];
    %%
    for ii=1:numel(Fnows)
        dnow=Dnows{ii};
        mkdirp([DR  dnow])
        fnow=Fnows{ii};
        mkdirp([DR  fnow])
    end
    %%
    for ii=1:numel(Fnows)
        fnow=Fnows{ii};
        dnow=Dnows{ii};
        catINPUT(fnow)
        
        
%         
%         if ii==1
%             todoPre;
%         end
%         try
%             todoCore;
%         catch 
%             continue
%         end
%         todoPost(DR,dnow,Rdata);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function catINPUT(fnow)
    try system(['mv INPUT.m INPUTold.m']), end
    system(['more INPUTupper.m > INPUT.m'])
    system(['more INPUT' fnow '.m >> INPUT.m'])
    system(['cp -r  *.m SUBS .git ../' fnow '/'])
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function todoPre
    S00b_prep_data
    S01_BruntVaisRossby
    S02_infer_fields
    S03_contours
    S06_init_output_maps
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function todoCore
    S04_filter_eddies
    S05_track_eddies
    %     S04b_analyzeEddyThresh
    S08_analyze_tracks
    %     S09_drawPlots
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function todoPost(DR,dnow,Rdata)
    system(['rm -rf ' DR dnow '/' 'EDDIES'])
    system(['rm -rf ' DR dnow '/' 'TRACKS'])
    system(['rm -rf ' DR dnow '/' 'CUTS'])
    system(['rm -rf ' DR dnow '/' 'ANALYZED'])
    
    system(['mv ' Rdata 'EDDIES ' DR dnow '/'])
    system(['mv ' Rdata 'TRACKS ' DR dnow '/'])
    system(['mv ' Rdata 'ANALYZED ' DR dnow '/'])
    
    cutdir=[Rdata 'CUTS/'];
    cut=dir([cutdir 'CUT_*.mat']);
    mkdirp([DR dnow '/CUTS'])
    system(['cp ' cutdir cut(1).name ' ' DR dnow '/CUTS/'])
    
    system(['cp ' cutdir  ' DD.mat protoMaps.mat window.mat meanSSH.mat ' DR dnow '/'])
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

