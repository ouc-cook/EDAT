% edited by NK
%
%   PARFOR_PROGRESS Progress monitor (progress bar) that works with parfor.
%   PARFOR_PROGRESS works by creating a file called parfor_progress.txt in
%   your working directory, and then keeping track of the parfor loop's
%   progress within that file. This workaround is necessary because parfor
%   workers cannot communicate with one another so there is no simple way
%   to know which iterations have finished and which haven't.
%
%   PARFOR_PROGRESS(N) initializes the progress monitor for a set of N
%   upcoming calculations.
%
%   PARFOR_PROGRESS updates the progress inside your parfor loop and
%   displays an updated progress bar.
%
%   PARFOR_PROGRESS(0) deletes parfor_progress.txt and finalizes progress
%   bar.
%
%   To suppress output from any of these functions, just ask for a return
%   variable from the function calls, like PERCENT = PARFOR_PROGRESS which
%   returns the percentage of completion.
%
%   Example:
%
%      N = 100;
%      parfor_progress(N);
%      parfor i=1:N
%         pause(rand); % Replace with real code
%         parfor_progress;
%      end
%      parfor_progress(0);
%
%   See also PARFOR.

% By Jeremy Scheff - jdscheff@gmail.com - http://www.jeremyscheff.com/
function parfor_progress(N)

    files.prog = '.parfor_progress.txt';
    files.time = '.parfor_progress_time.txt';

    if exist('N','var')
        if N > 0
            initCase(N,files)
        elseif N == 0
            closeCase(files)
        end
    else
        runningCase(files)
    end
end

function closeCase(files)
    delete(files.prog);
    delete(files.time);
    disp('done');
end

function runningCase(files)
    if ~exist(files.prog, 'file')
        error('%s not found. Run PARFOR_PROGRESS(N) before PARFOR_PROGRESS to initialize %s.',files,files);
    end
    f = fopen(files.prog, 'a');
    fprintf(f, '1\n');
    fclose(f);
    f = fopen(files.prog, 'r');
    filedata = fscanf(f, '%d');
    progress = filedata(2:end);
    N = filedata(1);
    fclose(f);
    percent = (length(progress))/N*100;

    perc = sprintf('%3.0f%%', percent); % 4 characters wide, percentage
%     disp([repmat(char(8), 1, (w+9)), char(10), perc, '[', repmat('=', 1, round(percent*w/100)), '>', repmat(' ', 1, w - round(percent*w/100)), ']']);
    %%

    f = fopen(files.time, 'r');
    initTime = str2double(fscanf(f, '%s'));
    fclose(f);
    timeSoFar  = now - initTime;
    timeTotal  = timeSoFar/percent * 100;
    timeToGo   = timeTotal - timeSoFar;

    timeToGoStr  =  datestr(timeToGo,'dd - HH:MM:SS');
    fprintf('percent done: %s\nto go: %s\n',perc,timeToGoStr);
end

function initCase(N,files)

		system(sprintf('rm -f %s %s',files.prog,files.time));

    f = fopen(files.prog, 'w');
    if f<0
        error('Do you have write permissions for %s?', pwd);
    end
    fprintf(f, '%d\n', N); % Save N at the top of progress.txt

    %%
    f = fopen(files.time, 'w');
    fprintf(f, '%6.5f\n', now); % Save N at the top of progress.txt
    fclose(f);
end
