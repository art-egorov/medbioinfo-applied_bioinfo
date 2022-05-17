# MedBioinfo 2022 Applied Bioinformatics
## Shared git repo for re-analysis

### Data source

Data is from Daniel Castañeda-Mogollón et al. Dec 2021 https://www.sciencedirect.com/science/article/pii/S1386653221002924

Samples (either Nasopharyngeal or Throat swabs) from 125 patients, either COVID+ or COVID- by PCR, were subjected to Illumina sequencing (one RNA and one DNA sequencing run for each patient).

### Aim of the re-analysis

Use k-mer based binning of the raw reads to identify potential human pathogens in the samples (including SARS-CoV-2).

To investigate, amongst others: 
 - correlation between COVID+/- PCR status and SARS sequence presence in metatranscriptomes
 - correlation between SARS2 infection and presence of known viral/bacterial co-pathogens
 - effectiveness of SARS2 detection with regards swab type (Nasopharyngeal or Throat)

Each course participant is in charge of a subset of the 250 total samples sequenced. Results will then be compiled to allow overall analysis of the full dataset.

### Structure of the shared repository

 - ```data``` contains the original data from Castañeda-Mogollón (**read only**, ie no modifications to be made!)
 - ```docs``` contains documentation (eg Jupyter notebooks, papers etc.)
 - ```scripts``` will contain any scripts used in the analysis workflow (eg SLURM bash scripts)
 - ```analyses``` will contain results of the analyses, such as transformed datasets, output files, and figures
 
Because of their large size, the original raw FASTQ sequence files will be excluded from git tracking via the .gitignore file. This is reproducible-friendly because these FASTQ raw files will be considered strictly read only, and therefore can be re-instanciated simply by executing the download commands that will be documented in the bash jupyter notebooks.
 
### Initial data
 - the raw sample metadata annotation file (downloaded from SRA below) is in ```data/SraRunTable.csv```
 - a copy of the Castañeda-Mogollón et al. paper is in ```docs/Castaneda-Mogollon_et_al_J_Clinical_Vir_Dec_2021.pdf```
 
### Organisation of the collaborative analysis
- the raw sequencing files archived at the NCBI SRA https://trace.ncbi.nlm.nih.gov/Traces/study/?acc=PRJEB47870 will be downloaded in ```data/```
- data needed to collaborate will be stored in the SQLite database in ```analyses/sample_collab.db```
  - table ```samples``` is a direct DB import of ```data/SraRunTable.csv```
  - table ```users``` will hold the list of course participants (field ```username``` is your IFB account login)
  - samples to users dispatch to be made in table ```sample2user```
