%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 10-Oct-2013 16:53:06
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% dataToCheck - either raw,CUTS,CONTS etc
function DD = initialise(dataToCheck)
    %% basic settings
    %     preInits;
    %% user input
    DD = getUserInput;
    %% append time info
    DD.time = catstruct(DD.time, timestuff(DD.time));
    %% scan for files and append
    DD.path = catstruct(DD.path,findfiles(DD));
    %% scan data 2 be checked
    if ~isempty(dataToCheck)
        DD = checkData(DD,dataToCheck);
    end
    %% load workers
    DD.threads.num = init_threads(DD.threads.num);
    %% show some info
    dispFileStatus(DD.path)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function preInits %#ok<DEFNU>
    addpath(genpath('./'));
    rehash;
    clc;
    format shortg;
    dbstop if error;
    set(0,'DefaultTextInterpreter', 'LaTeX');
    warning('off','parallel:convenience:RunningJobsExist')
    warning('off','parallel:job:DestructionOfUnavailableJob')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DD = checkData(DD,toCheck)
    %% init
    DD.time = initChecks(DD,toCheck);
    %% check for each needed file
    DD.time.passed = checkForFiles(DD.time);
    %% calc new del_t's in accord with missing files
    checks.del_t_full = buildNewDt(DD.time);
    %% append info
    checks.passedTotal = sum(DD.time.passed);
    checks.passed(checks.passedTotal) = struct;
    temp = num2cell(DD.time.timesteps.n(DD.time.passed))';
    [checks.passed.daynums] = deal(temp{:});
    %% find corresponding filenames
    [checks.passed] = getFnames(DD,checks,toCheck);
    %% disp found files
    filedisps(checks);
    %% append
    DD.checks = checks;
    DD.checks.del_t = [nan; checks.del_t_full(~isnan(checks.del_t_full))];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TT=initChecks(DD,toCheck)
    checkNoDataCase(DD.path.(toCheck));
    %% get filenames
    TT = DD.time;
    TT.existant.filesall = extractfield(DD.path.(toCheck).files,'name');
    %% cat numbers in filenames (for speed)
    dateOnly.s = regexp(cat(2,TT.existant.filesall{:}),'\d{8}','match');
    dateOnly.n = cellfun(@(c) datenum(c,'yyyymmdd'),dateOnly.s);
    TT.existant.fcats = cell2mat(cellfun(@(c) ['-' c],dateOnly.s,'uniformoutput',false));
    %% correct start date if not exactly on existing time step or not within range
    [~,ii] = min(abs(dateOnly.n-TT.from.num));
    offset = dateOnly.n(ii) - TT.from.num ;
    %% shift ".from"
    TT.from.num = TT.from.num + offset;
    TT.from.str = datestr(TT.from.num,'yyyymmdd');
    %% shift ".till" also to keep const time span
    TT.till.num = TT.till.num + offset;
    TT.till.str = datestr(TT.till.num,'yyyymmdd');
    %% correct end date if not exactly on existing time step or not within range
    [~,ii] = min(abs(dateOnly.n-TT.till.num));
    offset = dateOnly.n(ii) - TT.till.num ;
    TT.till.num = TT.till.num + offset;
    TT.till.str = datestr(TT.till.num,'yyyymmdd');
    TT.span = TT.till.num - TT.from.num + 1;
    disp(['corrected date range to ' datestr(TT.from.num) ' - ' datestr(TT.till.num)])
    %% init time-steps vector
    TT.timesteps.n = TT.from.num:TT.delta_t:TT.till.num;
    TT.timesteps.s = datestr(TT.timesteps.n,'yyyymmdd');
    %% init new delta t and "existing" vector (.passed)
    TT.passed = false(numel(TT.timesteps.n),1);
    TT.del_t = nan(size(TT.passed));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function checkNoDataCase(toCheck)
    if isempty(toCheck.files)
        error('err:noFiles',['no files found in ' toCheck.name])
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function filedisps(checks)
    disp(['found '])
    for ff=1:numel(checks.passed)
        disp([checks.passed(ff).filenames])
    end
    disp(['total of ' num2str(numel(checks.passed))])
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pass = checkForFiles(TT)
    pass = TT.passed;
    for tt = 1:numel(TT.passed);
        %% look for date string in cat'ed string of all filenames
        if ~isempty(strfind(TT.existant.fcats, TT.timesteps.s(tt,:)))
            pass(tt)=true;
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function del_t = buildNewDt(TT)
    del_t = nan(TT.span,1);
    tempdelt = TT.delta_t; % regular timestep
    for tt = 2:numel(TT.passed);
        if ~TT.passed(tt)
            %% flag del_t where not applicable
            del_t(tt)=nan;
            %% increase current del_t by one increment
            tempdelt=tempdelt + TT.delta_t;
        else
            %% if file exists, use accumulated delt_t
            del_t(tt) = tempdelt;
            %% reset tempdelt
            tempdelt = TT.delta_t;
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function passed = getFnames(DD,checks,toCheck)
    passed = checks.passed;
    path = DD.path.(toCheck);
    pattern = DD.pattern.fname;
    timestr = cellfun(@(x) datestr(x,'yyyymmdd'),{checks.passed.daynums}','uniformoutput',false); % only passed ones
    for cc = 1:numel(timestr)
        ts = timestr{cc};
        if strcmp(toCheck,'raw') % raw filenames relevant
            passed(cc).filenames = [path.name, strrep(DD.map.in.fname, 'yyyymmdd',ts)];
        else % build new filenames
            geo = DD.map.in;
            file.out = strrep(strrep(pattern, 'yyyymmdd',ts),'CUT',DD.pattern.prefix.(toCheck));
            passed(cc).filenames = NSWE2nums(path.name,file.out,geo,ts);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function T = timestuff(T)
    T.from.num = datenum(T.from.str,'yyyymmdd');
    T.till.num = datenum(T.till.str,'yyyymmdd');
    T.span = T.till.num-T.from.num+1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function PATH = findfiles(DD)
    %%
    PATH = DD.path;
    PATH.root = ['../data' PATH.OutDirBaseName '/'];
    PATH.code = [PATH.root, 'code/'];
    PATH.codesubs = [PATH.root, 'code/SUBS/'];
    PATH.cuts.name = [PATH.root, 'CUTS/'];
    PATH.conts.name = [PATH.root, 'CONTS/'];
    PATH.eddies.name = [PATH.root,'EDDYS/'];
    PATH.tracks.name = [PATH.root,'TRACKS/'];
    PATH.Rossby.name = [PATH.root,'ROSSBY/'];
    PATH.Rossby.Nfile = [PATH.Rossby.name,'N.cdf']; % TODO ?
    
    %% create nonexistant dirs
    mkDirs(PATH)
    %%
    [~,~,ext.raw] = fileparts(DD.map.in.fname);
    patt = strsplit(DD.map.in.fname,'yyyymmdd');
    PATH.raw.files = dir2([PATH.raw.name,patt{1},'*']);
    PATH.protoMaps.file = [PATH.root, 'protoMaps.mat'];   
    PATH.meanSsh.file = [PATH.root, 'meanSSH.mat'];
    PATH.cuts.files = dir2([PATH.cuts.name,'*.mat']);
    PATH.conts.files = dir2([PATH.conts.name,'*.mat']);
    PATH.eddies.files = dir2([PATH.eddies.name,'*.mat']);
    PATH.tracks.files = dir2([PATH.tracks.name,'*.mat']);
    PATH.Rossby.files = dir2([PATH.Rossby.name,'*.mat']);
    %%
    PATH.windowFile = [PATH.root 'window.mat'];
    PATH.coriolisFile = [PATH.root 'coriolis.mat'];
end
% TODO save all as tempfiles eg CUTS etc too
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mkDirs(path)
    %%
    mkdirp(path.root);  
    mkdirp(path.code);
    mkdirp(path.codesubs);
    mkdirp(path.cuts.name);
    mkdirp(path.conts.name);
    mkdirp(path.eddies.name);
    mkdirp([path.eddies.name,'tmp']);
    mkdirp(path.tracks.name);  
    mkdirp(path.Rossby.name);
    %%
    system(['cp ./*.m ' path.code]);
    system(['cp ./SUBS/*.m ' path.codesubs]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dispFileStatus(p)
    FN = fieldnames(p)';
    for ii = 1:numel(FN);fn = FN{ii};
        if isfield(p.(fn),'files') && isfield(p.(fn),'name')
            disp(['found ' num2str(numel(p.(fn).files)) ' files in ' p.(fn).name]);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
