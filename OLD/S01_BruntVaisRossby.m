%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 20-Jun-2014 16:53:06
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function S01_BruntVaisRossby
    %% init
    DD=initialise([],mfilename);
    returnCase= ~DD.switchs.RossbyStuff || (numel(DD.path.Rossby.files)>1 && ~DD.overwrite);
    if returnCase ,return;end
    %%
    switch DD.parameters.Nknown
        case false
            S01b_fromTS
        case true
            S01b_fromRaw
    end
end