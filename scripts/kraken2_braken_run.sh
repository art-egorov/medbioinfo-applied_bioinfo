#!/bin/bash
#
#SBATCH --partition=fast             # long, fast, etc.
#SBATCH --ntasks=1                   # nb of *tasks* to be run in // (usually 1), this task can be multithreaded (see cpus-per-task)
#SBATCH --nodes=1                    # nb of nodes to reserve for each task (usually 1)
#SBATCH --cpus-per-task=5            # nb of cpu (in fact cores) to reserve for each task /!\ job killed if commands below use more cores
#SBATCH --mem=65GB                  # amount of RAM to reserve for the tasks /!\ job killed if commands below use more RAM
#SBATCH --time=0-10:00               # maximal wall clock duration (D-HH:MM) /!\ job killed if commands below take more time than reservation
#SBATCH --array=1-14   #SLURM_ARRAY_TASK_ID
#SBATCH -o ./slurm_output/slurm.%A.%a.out   # standard output (STDOUT) redirected to these files (with Job ID and array ID in file names)
#SBATCH -e ./slurm_output/slurm.%A.%a.err   # standard error  (STDERR) redirected to these files (with Job ID and array ID in file names)
# /!\ Note that the ./outputs/ dir above needs to exist in the dir where script is submitted **prior** to submitting this script
#SBATCH --mail-type END              # when to send an email notiification (END = when the whole sbatch array is finished)
#SBATCH --mail-user me@geemail.com

#################################################################
# Preparing work (cd to working dir, get hold of input data, convert/un-compress input data when needed etc.)
workdir="/shared/projects/form_2022_19/artyom/sars2copath"
blastn_database="/shared/projects/form_2022_19/artyom/sars2copath/data/blast_db/viral"
query_dir="/shared/projects/form_2022_19/artyom/sars2copath/data/sra_fastq"
acc_numbers="/shared/projects/form_2022_19/artyom/sars2copath/analyses/aegorov_run_accessions.txt"

echo START: `date`

module load seqkit
module load kraken2
module load bracken

cd ${workdir}


accnum=$(sed -n "$SLURM_ARRAY_TASK_ID"p ${acc_numbers})
input_file_1=${query_dir}/${accnum}_1.fastq.gz
input_file_2=${query_dir}/${accnum}_2.fastq.gz
echo "$accnum"

#srun --job-name=${accnum}_kraken kraken2 --paired --gzip-compressed --report ./data/kraken2_reports/${accnum}.report  --threads ${SLURM_CPUS_PER_TASK}  --db /shared/projects/form_2022_19/kraken2/arch_bact_vir_hum_protoz_fung/   --output ./data/kraken2_output/${accnum}_results.tsv  ${input_file_1} ${input_file_2}
srun --job-name=${accnum}_braken bracken -d /shared/projects/form_2022_19/kraken2/arch_bact_vir_hum_protoz_fung/ -i ./data/kraken2_reports/${accnum}.report -w ./data/kraken2_output/${accnum}_results.tsv -o ./data/bracken_output/${accnum}_res.tsv -t 5 -r 50  


echo END: `date`
