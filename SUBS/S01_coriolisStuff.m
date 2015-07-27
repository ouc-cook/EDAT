function out = S01_coriolisStuff(lat)
    %% omega
    out.Omega = angularFreqEarth;
    %% f
    out.f = 2*out.Omega*sind(lat);
    %% beta
    out.beta = 2*out.Omega/earthRadius*cosd(lat);
    %% gravity
    out.g = sw_g(lat,zeros(size(lat)));
    %% g/f
    out.GOverF = out.g./out.f;
end
