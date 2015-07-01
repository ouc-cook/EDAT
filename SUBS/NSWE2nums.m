function out=NSWE2nums(pathout,filename,geo,timestr)   
    out=strrep(filename,'SSS',sprintf('%+03d',round(geo.south))); %#ok<*NASGU>
    out=strrep(out, 'NNN',sprintf('%+03d',round(geo.north)) );
    out=strrep(out, 'WWW',sprintf('%03d', round(wrapTo360(geo.west))));
    out=strrep(out, 'EEE',sprintf('%03d',round(wrapTo360(geo.east))));
    out=[pathout, strrep(out, 'yyyymmdd',timestr)]; 
end