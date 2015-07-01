function conclude(DD,noOutput)  %#ok<INUSD>
    if ~exist('noOutput','var')
        output(DD);
    end
    save_info;
    delete ./.comm*.mat
end
% #########################################################################
function output(DD)
    allData=dir(DD.path.root);
    allData =allData(cat(1,allData.isdir));
    allData =allData(3:end);
    [~,lastIdx]=max(cat(1,allData.datenum));
    relevantDir=allData(lastIdx);
    relevantDir.fullfile=fullfile(DD.path.root,  relevantDir.name);
    relevantDir.what=what( relevantDir.fullfile);
    %%
    inform(DD.monitor.tic)
end
% #########################################################################
function inform(Dtic)
    disp([' ']);
    disp([' ']);
    disp([' ']);
    disp([mfilename ' - SUCCESS!!!']);
    disp([' ']);
    disp(['time used: '])  ;
    daysUsed=toc(Dtic)/60/60/24;
    disp(datestr(daysUsed,'dd-HH:MM:SS',0));
    disp([' ']);
end
% #########################################################################