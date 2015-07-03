function TS = tempSaltKeys
    TS.dir = '/scratch/uni/ifmto/u300065/TempSaltUV/';
    TS.keys.lat = 'U_LAT_2D';
    TS.keys.lon = 'U_LON_2D';
    TS.keys.salt = 'SALT';
    TS.keys.temp = 'TEMP';
    TS.keys.depth = 'depth_t';
    %%
    TS.files = dir2([TS.dir,'*.nc']);
    TS.numChunks = 28; % number of chunks for brunt väis calculations
    TS.salinityFactor = 1000;
end