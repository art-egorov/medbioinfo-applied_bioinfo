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
# We can always check whether trimming was performed or wasn't simply by looking at read length distribution
# Since after sequencing raw reads have to have the same length, here we can see a bit skewed distibution, then, it was trimmed
# in addition, there is no adapter seqs detected and quality of reads at 3' end is fine
echo "Merging paired end reads"
module load flash2
mkdir ../data/merged_pairs
# i tested flash2 with one file and i got that ~85% of reads were combined with avg_len = 153, max_len = 292 
# it seems that a lot of pairs are overlapped 
date
srun --cpus-per-task=4 --time=00:30:00 xargs -a aegorov_run_accessions.txt -n 1 -I{} flash2 --threads=4 -z --output-directory=../data/merged_pairs/ --output-prefix={}.flash ../data/sra_fastq/{}_1.fastq.gz ../data/sra_fastq/{}_2.fastq.gz 2>&1 | tee aegorov_flash2.log
echo "Read mapping to check for PhiX contamination"
date
mkdir ../data/reference_seqs
echo "Downloading Phix Genome"
efetch -db nuccore -id NC_001422 -format fasta > ../data/reference_seqs/PhiX_NC_001422.fna
echo "Creating bowtie db"
mkdir ../data/bowtie2_DBs
module load bowtie2
srun bowtie2-build -f ../data/reference_seqs/PhiX_NC_001422.fna ../data/bowtie2_DBs/PhiX_bowtie2_DB
echo "bowtie analysis"
mkdir bowtie
srun --cpus-per-task=8 xargs -a aegorov_run_accessions.txt -n 1 -I{} bowtie2 -x ../data/bowtie2_DBs/PhiX_bowtie2_DB -U ../data/merged_pairs/{}.flash.extendedFrags.fastq.gz -S bowtie/aegorov_merged2PhiX.sam --threads 8 --no-unal 2>&1 | tee bowtie/aegorov_bowtie_merged2PhiX.log
# I didn't observed any alignments to PhiX
echo "Alignments to SARS-CoV2"
efetch -db nuccore -id NC_045512 -format fasta > ../data/reference_seqs/SARS_CoV2_NC_045512.fna
srun bowtie2-build -f ../data/reference_seqs/SARS_CoV2_NC_045512.fna ../data/bowtie2_DBs/SARS_CoV2_bowtie2_DB
srun --cpus-per-task=8 xargs -a aegorov_run_accessions.txt -n 1 -I{} bowtie2 -x ../data/bowtie2_DBs/SARS_CoV2_bowtie2_DB -U ../data/merged_pairs/{}.flash.extendedFrags.fastq.gz -S bowtie/aegorov_merged2SARS_CoV2.sam --threads 8 --no-unal 2>&1 | tee bowtie/aegorov_bowtie_merged2SARS_CoV2.log
# I didn't get any alignments again
# I checked my samples with SQL:
sqlite3  -batch  /shared/projects/form_2022_19/pascal/central_database/sample_collab.db " select *   from  sample_annot WHERE patient_code in (select patient_code from sample2bioinformatician WHERE username = 'aegorov' ) ";
#and i got that all my samples with negative SARS, which could be an explanation
date
echo "Alignments Streptococcus oralis (NZ_CP065707.1) "
efetch -db nuccore -id NZ_CP065707.1 -format fasta > ../data/reference_seqs/S_oralis_NZ_CP065707.1.fna
srun bowtie2-build -f ../data/reference_seqs/S_oralis_NZ_CP065707.1.fna ../data/bowtie2_DBs/S_oralis_bowtie2_DB
srun --cpus-per-task=8 xargs -a aegorov_run_accessions.txt -n 1 -I{} bowtie2 -x ../data/bowtie2_DBs/S_oralis_bowtie2_DB -U ../data/merged_pairs/{}.flash.extendedFrags.fastq.gz -S bowtie/aegorov_merged2S_oralis.sam --threads 8 --no-unal 2>&1 | tee bowtie/aegorov_bowtie_merged2S_oralis.log
#Finally, I observed hits! (1-15% per sample)
echo "MultiQC analysis"
date
module load multiqc
srun multiqc --force --title "aegorov sample sub-set" ../data/merged_pairs/ ./fastqc/ ./phingamp_flash2.log ./bowtie/