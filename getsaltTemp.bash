#!/bin/bash
dirin="/scratch/uni/ifmto/u241194/DAILY/EULERIAN/1994-1995/"

ls -1  ${dirin}*1994*tar | while read line; do
 file=${line}
 echo extracting salt from $file
 tar -xvf $file --wildcards --no-anchored '*SALT*'
 echo extracting temp from $file
 tar -xvf $file --wildcards --no-anchored '*TEMP*'
done


ls -1  ${dirin}*1995*tar | while read line; do
 file=${line}
 echo extracting salt from $file
 tar -xvf $file --wildcards --no-anchored '*SALT*'
 echo extracting temp from $file
 tar -xvf $file --wildcards --no-anchored '*TEMP*'
done
