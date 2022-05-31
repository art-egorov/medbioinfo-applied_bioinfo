#!/bin/bash
echo "script start and cd into my dir"
cd /shared/projects/form_2022_19/artyom/sars2copath/analyses/
date
echo "getting my run accessions ids"
sqlite3 -noheader -csv -batch  /shared/projects/form_2022_19/pascal/central_database/sample_collab.db " select run_accession from sample_annot spl left join sample2bioinformatician s2b using(patient_code) where username='aegorov';" > aegorov_run_accessions.txt
echo "setting modules"
module load sra-tools
date
echo "create ../data/sra_fastq dir"
mkdir ../data/sra_fastq/dir
echo "downloading fastq.gz files"
date
cat aegorov_run_accessions.txt | srun --cpus-per-task=1 --time=00:30:00 xargs fastq-dump --readids --gzip --outdir ../data/sra_fastq/ --disable-multithreading --split-e 
date
echo "Number of downloaded fastq files"
ls -l ../data/sra_fastq | grep -c 'ERR'
echo "loading the module seqkit"
module load seqkit
#i tried manually several seqkit commands
# for example, with seqkit stat -a ../data/sra_fastq/ERR6913187_1.fastq.gz i got info about num of sequences
# to compare it with written in our db i used sqlite3  -batch  /shared/projects/form_2022_19/pascal/central_database/sample_collab.db " select *  from sample_annot spl where run_accession='ERR6913187' ";
# to manually check adapter we can use: zcat ../data/sra_fastq/ERR6913187_1.fastq.gz | grep AGCACACGTCTGAACTCCAGTCA
echo "FastQC analysis"
module load fastqc
date
srun --cpus-per-task=4 --time=00:30:00 xargs -I{} -a aegorov_run_accessions.txt fastqc --outdir ./fastqc/ --threads 4 --noextract ../data/sra_fastq/{}_1.fastq.gz ../data/sra_fastq/{}_2.fastq.gz 

