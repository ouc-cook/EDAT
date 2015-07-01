% SETDEFAULTS2 sets the default structure values 
%    SOUT = SETDEFAULTS(S, SDEF) reproduces in S 
%    all the structure fields, and their values,  that exist in 
%    SDEF that do not exist in S. 

function sout = setdefaults2(s,sdef)
sout = sdef;
for f = fieldnames(s)'
    sout = setfield(sout,f{1},getfield(s,f{1}));
end