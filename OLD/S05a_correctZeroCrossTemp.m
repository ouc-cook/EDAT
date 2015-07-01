%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 23-Jan-2015 17:04:31
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% inter-allocate different time steps to determine tracks of eddies
function S05a_correctZeroCrossTemp
    %% init
    DD=initialise('eddies',mfilename);
    %% parallel!
    init_threads(DD.threads.num);
    main(DD)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD)
    senses = DD.FieldKeys.senses;
    files=extractfield(dir2(DD.path.eddies.name),'fullname');
    files=files(3:end);
    
    LON = getfield(getfield(load([DD.path.cuts.name DD.path.cuts.files(1).name]),'fields'),'lon');
    LON180 = wrapTo180(LON);
    
    %     parfor ff=1:numel(files)
    for ff=1:numel(files)
        parforloop(files,senses,ff,LON180,LON)  ;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function parforloop(files,senses,ff,LON180,LON)
    disp(['loading' files{ff}]);
    E = load(files{ff});
    for ss=1:2
        sen=senses{ss};
        eddy=E.(sen) ;
        for ee=1:numel(eddy)
            x=eddy(ee).trackref.x;
            y=eddy(ee).trackref.y;
            lonr=LON(round(y),round(x));
            %             if (lonr>358) || (lonr<2)
            if (lonr>359.5) || (lonr<.5)
                
                newlon = wrapTo360(interp2(LON180,x,y));
                %                 fprintf('correcting %f to %f\n',eddy(ee).geo.lon,newlon)
                disp(num2str(eddy(ee).geo.lon-newlon));
                eddy(ee).geo.lon =  newlon;
            end
        end
        E = setfield(E,sen,eddy);
    end
    save(files{ff},'-struct','E') ;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
