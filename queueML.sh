#!/bin/bash
#SBATCH --job-name=nikotestA
#SBATCH --output=JobName-%j.out
#SBATCH --error=JobName-%j.err
#SBATCH --partition=uni-compute
##SBATCH --nodes=1
##SBATCH --ntasks-per-node=4

# if you want to use the module system:
source /sw/share/Modules/init/bash
# after initializiation you can load a module
#module load openmpi_ib/1.4.5-static-intel11
module load matlab/2015a

# below your job commands:
matlab -nodisplay < queueJob.m
