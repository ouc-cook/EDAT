function f = coriolis(phi)
    sidDayInSecs = 23.9344696 *60*60;
    Omega = 2*pi/sidDayInSecs;
    f = 2*Omega .* sind(phi);
end