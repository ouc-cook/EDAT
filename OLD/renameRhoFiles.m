
rhoFiles=dir('./rho_*.nc');


strtdate=datenum('19940201','yyyymmdd');

dateN=strtdate;
for ii=1:numel(rhoFiles)
    F=rhoFiles(ii).name;
    dateS=datestr(dateN,'yyyymmdd');
    newname=sprintf('rho_%s.nc',dateS);
    todo=sprintf('mv %s %s',F,newname);
    disp(todo);
    system(todo);
    dateN=dateN+1;
end

