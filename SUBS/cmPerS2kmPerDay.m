function [ kmpd ] = cmPerS2kmPerDay( cmps )
    x = cmps;
    x = x/100; % cm2m
    x = x/1000; % m2km
    x = x*60; % s2min
    x = x*60; % min2h
    x = x*24; % h2day
    kmpd = x;
end

