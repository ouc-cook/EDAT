function buildBirthDeathMaps(tracks)
    TODO
    N = numel(tracks);
    BD.birth.lat = nan(N,1);
    BD.birth.lon = nan(N,1);
    BD.death.lat = nan(N,1);
    BD.death.lon = nan(N,1);
    for tt = 1:numel(tracks)
        bd = getfield(getfieldload(tracks(tt).fullname,'analyzed'),'birthdeath');
        BD.birth.lat(tt) = bd.birth.lat;
        BD.birth.lon(tt) = bd.birth.lon;
        BD.death.lat(tt) = bd.death.lat;
        BD.death.lon(tt) = bd.death.lon;
    end
end