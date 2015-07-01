function simpleTrackPlot2
    %    DD = initialise([],mfilename);
    load DD
    
    eddie = load([DD.path.eddies.name DD.path.eddies.files(1).name]);
   
    
    
    LAT = cut.fields.lat;
    LON = cut.fields.lon;
   
    
    [~,mm] = max(cat(1,DD.path.tracks.files.bytes));
    
    
    TRa = getfield(load([DD.path.tracks.name DD.path.tracks.files(mm-1).name]),'track');
    
    
   geo= cat(1,TRa.geo)
    
   
   plot(cat(1,geo.lon),cat(1,geo.lat))
    
    
    
    
    
    
    
    
    
    for tt = 1:numel(TRa)
        tr = TRa(tt);
        ed.y = tr.coor.exact.y;
        ed.x = tr.coor.exact.x;
       
        tr.daynum
        
        
        SSH = cut.fields.ssh;
        
        
        
        
        plot(ed.y,ed.x)
        
        
        
        tra = trb;
    end
    
    
    
end