function memused =unixMem
    % get the parent process id
    [~,ppid] = unix(['ps -p $PPID -l | ' awkCol('PPID') ]);
    % get memory used by the parent process (resident set size)
    [~,memused] = unix(['ps -O rss -p ' strtrim(ppid) ' | awk ''NR>1 {print$2}'' ']);
    % rss is in kB, convert to bytes
    memused = str2double(memused)*1024 ;
end
function theStr = awkCol(colname)
    theStr  = ['awk ''{ if(NR==1) for(i=1;i<=NF;i++) { if($i~/' colname '/) { colnum=i;break} } else print $colnum }'' '];
end