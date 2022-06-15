#!/bin/bash
#
#SBATCH --partition=fast             # long, fast, etc.
#SBATCH --ntasks=1                   # nb of *tasks* to be run in // (usually 1), this task can be multithreaded (see cpus-per-task)
#SBATCH --nodes=1                    # nb of nodes to reserve for each task (usually 1)
#SBATCH --cpus-per-task=2            # nb of cpu (in fact cores) to reserve for each task /!\ job killed if commands below use more cores
#SBATCH --mem=5GB                  # amount of RAM to reserve for the tasks /!\ job killed if commands below use more RAM
#SBATCH --time=0-10:00               # maximal wall clock duration (D-HH:MM) /!\ job killed if commands below take more time than reservation
#SBATCH --array=1-14   #SLURM_ARRAY_TASK_ID
#SBATCH -o ./slurm_output/slurm.%A.%a.out   # standard output (STDOUT) redirected to these files (with Job ID and array ID in file names)
#SBATCH -e ./slurm_output/slurm.%A.%a.err   # standard error  (STDERR) redirected to these files (with Job ID and array ID in file names)
# /!\ Note that the ./outputs/ dir above needs to exist in the dir where script is submitted **prior** to submitting this script
#SBATCH --job-name=blastn        # name of the task as displayed in squeue & sacc, also encouraged as srun optional parameter
#SBATCH --mail-type END              # when to send an email notiification (END = when the whole sbatch array is finished)
#SBATCH --mail-user me@geemail.com

#################################################################
# Preparing work (cd to working dir, get hold of input data, convert/un-compress input data when needed etc.)
workdir="/shared/projects/form_2022_19/artyom/sars2copath"
blastn_database="/shared/projects/form_2022_19/artyom/sars2copath/data/blast_db/viral"
query_dir="/shared/projects/form_2022_19/artyom/sars2copath/data/merged_pairs"
acc_numbers="/shared/projects/form_2022_19/artyom/sars2copath/analyses/aegorov_run_accessions.txt"

echo START: `date`

module load blast
module load seqkit

mkdir -p ${workdir}/data/blastn_output      # -p because it creates all required dir levels **and** doesn't throw an error if the dir exists :)
cd ${workdir}


accnum=$(sed -n "$SLURM_ARRAY_TASK_ID"p ${acc_numbers})
input_file=${query_dir}/${accnum}.flash.extendedFrags.fastq.gz
echo "$accnum"
echo "$input_file"
zcat ${input_file} | seqkit fq2fa | head
srun --job-name=${accnum} seqkit fq2fa ${input_file} |  blastn -num_threads ${SLURM_CPUS_PER_TASK} -evalue 10e-5  -max_target_seqs 5 -perc_identity 70 -db ${blastn_database}   -outfmt 6 -out ./data/blastn_output/${accnum}_results.tsv 
 



echo END: `date`
