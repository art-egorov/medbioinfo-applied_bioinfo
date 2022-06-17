# Applied bioinformatics, <br> Medbioinfo school 
## Monday (13 June) 

### SQL

**The most useful commands:**  
SELECT, INSERT, UPDATE, DELETE + CREATE  
**loading table:**  
<code>sqlite3 path </code>  
**example of deleting:**  
<code> delete from bioinformaticians where username='df...'; </code>  
**for better visualisation run**  
<code>.mode column</code>  
**within jupyter you can use**:  
<code>sqlite3 -batch path_to_db "COMMAND" </code>

#### We need to discuss database design
One of the best thing that you can say which column should contain unique elements  
<code> .schema </code> allows you to get info about design of a table  
(it also shows how is was created)  
<code>CREATE TABLE "bioinformaticians"(           
  "username" TEXT NOT NULL PRIMARY KEY,     
  "firstname" TEXT NOT NULL,                
  "lastname" TEXT NOT NULL);</code>  
*PRIMARY KEY* means that it's like id - no rows with the same name.  
*NOT NULL* - each line has to contain data. 

**Another ex of schema for table sample2bioinformatician**

<code> CREATE TABLE "sample2bioinformatician"(
  "username" TEXT NOT NULL,
  "patient_code" TEXT NOT NULL,
  PRIMARY KEY (username, patient_code)
);
CREATE INDEX index_sample2bioinformatician_username ON sample2bioinformatician(username);
CREATE UNIQUE INDEX index_sample2bioinformatician_patient_code ON sample2bioinformatician(patient_code);
</code>  
PRIMARY KEY (username, patient_code) means that only unique pairs can be added.  
Indexes are really important especcialy for huge tables.  
CREATE UNIQUE INDEX means not only indexing but also that this column should contains unique 

####  Join

<code> select spl.patient_code, s2b.username from sample_annot spl left join sample2bioinformatician s2b using(patient_code) order by  s2b.username asc limit 2; </code>  
Adding new info:  
<code>"insert into sample2bioinformatician(username, patient_code) VALUE ('aegorov', 'P369');</code>


### 1 - sbatch SLURM scripting

#### SLURM stuff
**Useful commands:**  
SCANCEL, SBATCH (miltiple commands), SQUEUE -u username, sacct, SRUN (for single)  
To run stuff in background use ).  
<code>
$nohup gzip &\      
$..</code>  nohup gives the same as screen actually.  
Also slurm capture output in stdout and stderr files.  
You can also submit several jobs and make a queue of them (to tell when to start which).  

#### git stuff again

- firstly, i commited my changes <code>git commit -m "</code>
- then, i changed my branch <code> git checout initial_state </code>
- the, <code> git pull origin initial_state </code> command 
- then, i checkout in my branch and merged initial_state into it:
<code> git checkout artyom </code>  
<code> git merge initial_state </code>

### 2 - sbatch application: BLASTn of mini reads subsets versus refseq viral database


- in addition, i downloaded new added patients with and merged them:
<code> cat aegorov_run_accessions.txt  | sed -n '9,10p;11p;12p;13p;14p' | srun --cpus-per-task=1 --time=00:30:00 xargs fastq-dump --readids --gzip --outdir ../data/sra_fastq/ --disable-multithreading --split-e </code>  
And merged these new paired-end reads:  
<code> srun --cpus-per-task=4 --time=00:30:00 xargs -a aegorov_run_accessions.txt -n 1 -I{} flash2 --threads=4 -z --output-directory=../data/merged_pairs/ --output-prefix={}.flash ../data/sra_fastq/{}_1.fastq.gz ../data/sra_fastq/{}_2.fastq.gz 2>&1 | tee aegorov_flash2_v2.log </code>  
- Creating a new blastn subdir  
`mkdir blastn`
- loading blast  
`load module blast`  
- Creating a database  
` mkdir ../data/blast_db`  
`zcat /shared/projects/form_2022_19/refseq/viral.*gz | srun --cpus-per-task=4 makeblastdb -dbtype 'nucl' -out ../data/blast_db/viral -title refseq_viral`
- Checking our db:  
`blastdbcmd -info -db ../data/blast_db/viral`  
Output: *Database: refseq_viral  
        14,813 sequences; 469,447,120 total bases*
- Sometimes it's important not to forget using -parse_seqids command. (below is a command with additional checking how much sequences we got, and yes, it works)  
` seqkit range -r 1:10 ../data/merged_pairs/ERR6913191.flash.extendedFrags.fastq.gz  | seqkit fq2fa  | grep '>' | wc -l`
- then i created a dir for these files   
`mkdir ../data/subset_of_reads_in_fasta`  
- I've chosen the sample: ERR6913191 and run following command with a loop:  
<code> for i in 10 100 1000 do
 seqkit range -r 1:$i ../data/merged_pairs/ERR6913191.flash.extendedFrags.fastq.gz | seqkit fq2fa
 ../data/subset_of_reads_in_fasta/ERR6913191_subset_$i.fa done 
</code>. 
- To get stat of these files i used:  
`seqkit stat ../data/subset_of_reads_in_fasta/ERR6913191_subset_*   file`  
- `seqkit stat ../data/merged_pairs/ERR6913191.flash.extendedFrags.fastq.gz`  
- Finally, i created a bash scripts which allows to make blastn run  (*/shared/projects/form_2022_19/artyom/sars2copath/scripts/blastn_searching_for_subset_monday.sh*)  
- Then it was run with (the problem with a loop was because of line break in a wrong position -_-) :  
`sbatch blastn_searching_for_subset_monday.sh`

## Tuesday (14 June) 

### git  
To merge with not the latest commit from other branch we can copy an id of commit with `git log` and then run `git merge id`.
**How to remove one of the commit in the moddle?**
(for ex. we have A1,....A5 commits and we want to remove A2):  
Firstly, get a commit id with `git log`,
then, `git revert A2_id`.  
For removing the last commit we can just run `git revert`  
We also can use checkout to jump between commits with `get checkout commit_id`.  
** the first task**
- `git clone https://github.com/samuelflores/studentlist.git`
- `git branch artyom_egorov`
- `git checkout artyom_egorov`
- `echo 'Artyom Egorov' >> README.md`
- `git add README.md`
- `git commit -m "artyom's commit"`
- `git checkout main`
- `git pull -all`
- `git checkout jose_nakamoto`
- `git checkout artyom_egorov`
- `git merge jose_nakamoto`
- resolving a conflict
- `git add README.md`
- `git commit -m "Merging with Jose Nakamoto"`
- Then i merged with Osheen and then with a lof of others repos  
- In order to return in the last commit (erase all changes) RUN:  
`git checkout .`


**Back to our dataset with Pascal**  
- to track your runs use:  
 `sacct  --format=JobID,JobName%20,ReqCPUS,ReqMem,Timelimit,State,ExitCode,Start,elapsed,MaxRSS,NodeList,Account%15 -S 2022-05-10` 
- Be more careful with e-value treshold (10e-10 is fine).  
- then i made a new update to create tsv output.
### 4- sbatch job arrays application: BLASTn of full FASTQ versus refseq viral database
- For this task I created a bash script: */shared/projects/form_2022_19/artyom/sars2copath/scripts/blastn_real_run.sh* which sbatch job arrays. Output dir: */shared/projects/form_2022_19/artyom/sars2copath/data/blastn_output*
- Getting statistics  
- Firstly, counting and saving the results:  
`cat * | cut -f 2 |  sort | uniq -c | sort -gr > ../viral_ids_sorted.txt`  
- Then, fixing strange output of uniq -c command (replacing spaces with commas and taking only meaningful columns)  
`sed -E 's/^ +//'  viral_ids_sorted.txt | cut -d' ' -f 2 | xargs -I{} grep {}  /shared/projects/form_2022_19/refseq/viral.genomic.fna > viruses_names.txt `  
- Finally, using grep in order to get a description pard from seq id written in fasta files  
`cut -f2 -d , viral_ids_sorted_sep.txt | xargs -I{} grep {}  /shared/projects/form_2022_19/refseq/viral.genomic.fna > viruses_names.txt `  
- The last step is to paste it, because everything was sorted  
`paste viral_ids_sorted_sep.txt viral_names.txt | sed 's/\,/\ /g'  > viral_stat.txt`

## Wed (15 June)

Don't worget that we're using `--job-name ${accnum}` in sbatch job array in order to track needed recourses for a particular file. 


### 5 - Benchmarking to estimate cpu.hours
**Examples of regex**:  
`/ERR[0-9]+/` `/ERR./`  
(`.` - any character, `+` - at least one)  
For pattern at the beggining `/^ERR[0-9]+/` (`^` - looking for for a line which starts with it, `$` - ends with a pattern)  
For substitution it starts with `s/to replace/for what to replace/`  
- we can also grep corona in our blastn stat file with:  
`grep corona viral_stat.txt`  
` grep NC_045512 blastn_output/* | head`  

**Finally benchamrking**
- `sacct --format=JobID%20,JobName%18,ReqCPUS,ReqMem,Timelimit,State,ExitCode,Start,elapsed,CPUTime,MaxRSS,MaxVMSize,NodeList -S 2022-05-30`  
(elapsed - world clock, CPUTime.seconds - which time it takes if ther would be run on one CPU)  
- We also want to use CPUTimeRAW to make it readeble by mashines:  
`sacct --format=JobID%20,JobName%18,ReqCPUS,ReqMem,Timelimit,State,ExitCode,Start,elapsed,CPUTime,MaxRSS,MaxVMSize,NodeList -S 2022-05-30`  
- We can also modify it a bit in order to get only the last run (to avoid ambiguous ERR)  
`sacct --format=JobID%20,JobName%18,ReqCPUS,ReqMem,Timelimit,State,ExitCode,Start,elapsed,CPUTimeRaw,MaxRSS,MaxVMSize,NodeList -S 2022-05-30 | grep 23329085 | grep ERR > sacct_output_for_blastn.tsv`  
`sacct -P  --format=JobID%20,JobName%18,ReqCPUS,ReqMem,Timelimit,State,ExitCode,Start,elapsed,CPUTimeRaw,MaxRSS,MaxVMSize,NodeList -S 2022-05-30 | grep 23329085 | grep ERR > sacct_output_for_blastn.tsv `
- To create a table:  
`sqlite3 -batch -separator "|"  /shared/projects/form_2022_19/pascal/central_database/sample_collab.db ".import sacct_output_for_blastn_header.tsv  blastn_viral_resources_used"`  
- Checking:  
`sqlite3 -batch /shared/projects/form_2022_19/pascal/central_database/sample_collab.db "select * from blastn_viral_resources_used"`
- Getting the table structure
`sqlite3 -batch /shared/projects/form_2022_19/pascal/central_database/sample_collab.db -cmd ".schema blastn_viral_resources_used"`
- It was also indexed before in order to avoid ambiguous  
`sqlite3 -batch /shared/projects/form_2022_19/pascal/central_database/sample_collab.db "DELETE FROM blastn_viral_resources_used WHERE JobID='JobID';"`
- To solve problems:  
`sqlite3 -batch /shared/projects/form_2022_19/pascal/central_database/sample_collab.db "select * from blastn_viral_resources_used WHERE JobName LIKE '%blast%' "`  
`select JobName, CPUTimeRAW, MaxRSS, MaxRSS, MaxVMSize, read_count, base_count from blastn_viral_resources_used cpu inner join sample_annot  spl on cpu.JobName=spl.run_accession limit 5;`
- Finally plotting the results  (shared/projects/form_2022_19/artyom/sars2copath/analyses/plot_after_benchmarking.ipynb)


<a href="https://ibb.co/BtYmRSn"><img src="https://i.ibb.co/f2Tb7PD/figs.jpg" alt="figs" border="0" width=400px/></a>


**Running search against NT**
- Path to blastn db: /shared/bank/nt/current/flat/nt  
`srun --cpus-per-task 40 --mem 200GB --time 00:50:00 --job-name="searching_against_NT" blastn -num_threads 40 -evalue 10e-5 -db /shared/bank/nt/current/flat/nt -query ./subsets_of_reads_in_fasta/ERR6913191_subset_100.fa -outfmt 6 -out ./blastn_output_against_NT/results`
**Kraken**
You can see that blast takes an infinity time to make this search. Kraken2 can help. It uses K-mers to make it faster. 
- The Kraken database is here: /shared/projects/form_2022_19/kraken2/arch_bact_vir_hum_protoz_fung/
- The reason of using kraken: with blastn it takes 2.25min per sequence to search against NT. So, it's years for real data.
- You can ssh into a computer node to check how it's going. 
- kraken script: /shared/projects/form_2022_19/artyom/sars2copath/scripts/kraken2_run.sh
- Then we're gonna use bracken tool in order to devide classes' reads to subclasses' which got at least some reads.
- A bash script was updated with adding bracken (kraken2_braken_run.sh)
- Then, parsing it:  
- `sort -k6 -g -t $'\t' kraken_file`  
- `xargs -a ../../analyses/aegorov_run_accessions.txt -I{} sed -E 's/^/{}\t/' {}_res.tsv >> ../bracken_combined.tsv `
- ` grep -v "kraken_assigned_reads" bracken_combined.tsv > bracken_combined_no_headers.tsv `  
- `head -n 1 bracken_combined.tsv | sed -E 's/^\S+/sample/' > bracken_header.tsv`. 
- `cat bracken_header.tsv bracken_combined_no_headers.tsv > bracken_combined_with_header.tsv`
- Finally, uploading:
- `sqlite3 -batch -tabs /shared/projects/form_2022_19/pascal/central_database/sample_collab.db ".import --skip 1 /shared/projects/form_2022_19/artyom/sars2copath/data/bracken_combined_with_header.tsv bracken_abundances_long"` 
- THEN, MILLIONS TIME FIXING THE MESS
- `delete from bracken_abundances_long where fraction_total_reads is null;`

## Thu (16 June)

### 

- Running multiqc  
`srun multiqc --force --title "aegorov after kraken" ../data/merged_pairs/ ./fastqc/ ./bowtie/ ../data/kraken2_output/ ../data/kraken2_reports/ ../data/bracken_output/`
- Running krona  
`xargs -a aegorov_run_accessions.txt -I{} python3 /shared/home/phingamp/medbioinfo_folder/kraken2/KrakenTools/kreport2krona.py  -r kraken2_output/{}_results.tsv -o krona/{}.tsv`
- `/shared/home/phingamp/medbioinfo_folder/kraken2/bin/ktImportText  krona/ *`<img src="https://i.ibb.co/ChvtSJD/photo-2022-06-16-10-04-44.jpg" alt="figs" border="0" width=500px/>

- **playing with sql and our table**  
` select run_accession,sum(fraction_total_reads) from bracken_abundances_long group by run_accession;`    
| run_accession | sum(fraction_total_reads) |   
+---------------+---------------------------+   
| ERR6913101    | 0.99695                   |    
| ERR6913102    | 0.99461                   |  
| ERR6913103    | 0.987089999999999         |  
| ERR6913105    | 0.990039999999994         |  
| ERR6913106    | 0.999570000000003         |  
| ERR6913108    | 0.983419999999999         |  
| ERR6913111    | 0.99259                   |  
| ERR6913112    | 0.9596                    |  
We have to round in order to get 1 actually, we also removed some reads 
- can you list the first 20 samples with highest SARS-CoV-2 abundance?  
`select * from bracken_abundances_long  where taxon_name LIKE '%coronavirus%' group by run_accession  order  by fraction_total_reads desc limit 20;`<img src="https://i.ibb.co/myJFWSf/photo-2022-06-16-11-09-11.jpg" alt="photo-2022-06-16-11-09-11" border="0" width="900px">
- `select run_accession,nuc,host_disease_status,sum(fraction_total_reads) as frac,taxon_name from bracken_abundances_long abu left join sample_annot spl using(run_accession) where taxon_name='Severe acute respiratory syndrome-related coronavirus' group by run_accession order by frac desc;`
- `sqlite3 -cmd ".mode box" /shared/projects/form_2022_19/pascal/central_database/sample_collab.db`
- `select run_accession,nuc,host_disease_status,Ct,sum(fraction_total_reads) as frac,taxon_name from bracken_abundances_long abu left join sample_annot spl using(run_accession)  where taxon_name='Severe acute respiratory syndrome-related coronavirus' group by run_accession order by frac desc;`
- `select sum(new_est_reads) as total,taxon_name from bracken_abundances_long where taxon_name like '%virus%' group by taxonomy_id order by total desc;`
- `select sum(new_est_reads) as total,taxon_name from bracken_abundances_long  where taxon_name in('Dolosigranulum pigrum','Haemophilus influenzae','Haemophilus parainfluenzae','Klebsiella pneumoniae', 'Streptococcus pneumoniae','Staphylococcus aureus','coronavirus','Influenza A virus','Severe acute respiratory syndrome-related coronavirus') group by taxonomy_id order by total desc;`

- Then we played with R heatmap 

**Results:**
location of R script: `/shared/projects/form_2022_19/artyom/sars2copath/scripts/branken_abundance_heatmap_analysis.R `
<img src="https://i.ibb.co/jH6xjqg/photo-2022-06-17-12-31-52.jpg" alt="photo-2022-06-17-12-31-52" border="0" width=500px>
 
**snakemake**
- firstly, preparation and installation + downloading data for tutorial
- I'm not sure if it's needed to write all steps here, because it's written in tutorial. Working dir for this part is: /shared/projects/form_2022_19/artyom/snakemake-tutorial
<img src="https://i.ibb.co/WW8M12R/photo-2022-06-16-16-35-31.jpg" alt="photo-2022-06-16-16-35-31" border="0" height="400px">

## Fri (17 June)

**still snakemake 😬**  
I still can't understand why there is no way to specify logically input files, why output? 🫤  
Path to my snakemake file: `/shared/projects/form_2022_19/artyom/sars2copath/snakemake`. 
*(finally it works even with sbatch 🥳)*

## THE END ✨ 

### Thank you! 


