library(DBI)
library(ggplot2)
library(ggpubr)
library(plyr)
library(tidyr)
library(tidyverse)
library(ComplexHeatmap)
library("heatmaply")#mutate_if(is.numeric, funs(replace_na(., 0)))
library(RColorBrewer)


mydb = dbConnect(RSQLite::SQLite(),"/shared/projects/form_2022_19/pascal/central_database/sample_collab.db")


dbGetQuery(mydb, 'select count(distinct(run_accession)) from bracken_abundances_long ;')
dbGetQuery(mydb, 'select * from bracken_abundances_long  limit 5;')
db <- dbGetQuery(mydb, 'select * from bracken_abundances_long  ;')

db <- db %>% filter(str_detect(taxon_name, 'virus'))


#db <- db %>% select(run_accession,taxon_name,fraction_total_reads) %>% filter(fraction_total_reads>0.1)

db_matrix <- pivot_wider(db, id_cols = taxon_name, names_from = run_accession, values_from = fraction_total_reads)
rownames(db_matrix) <- db_matrix$taxon_name
db_matrix[is.na(db_matrix)] = 0
db_matrix <- as.matrix(db_matrix[2:156])

Heatmap(db_matrix)

#########
abun_long <- as_tibble(dbGetQuery(mydb, "select * from bracken_abundances_long abu left join sample_annot spl using(run_accession);"))
abun_long <- abun_long %>% mutate(fraction_nonhuman_reads=new_est_reads/read_count,fraction_total_reads_real=fraction_total_reads/total_reads,fraction_nonhuman_reads_log2=log2(fraction_nonhuman_reads))
print(abun_long)
samples <- dbGetQuery(mydb, 'SELECT * FROM sample_annot order by patient_code;')
samples <- as_tibble(samples) %>% mutate(across(where(is_character),as_factor))
print(samples)

abun_long %>% filter(str_detect(taxon_name, 'virus')) %>% arrange(nuc) %>% 
  ggplot(aes(host_subject_id, taxon_name, fill=log2(fraction_total_reads))) + 
  geom_raster(hjust = 0, vjust = 0) +
  scale_fill_distiller(palette = 'PiYG', name="Abundance") +# scale_fill_gradient(low="white", high="blue") +
  #scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = -12, limit = c(-16,-8), space = "Lab", name="Abundance")+
  ggtitle("Viral disversity in patient samples")+
  theme(plot.title = element_text(size = 20, face = "bold"),axis.text.x = element_text(angle = 45, vjust = 1, size = 12, hjust = 1)) +ylab("Virus")+xlab("Samples")
#coord_fixed()+
#theme_bw()

abun_wide %>% filter(str_detect(taxon_name, 'virus'))

abun_wide_samples <- colnames(abun_wide)[-1]
abun_wide_samples
sample_annot_rtPCR <- samples %>% filter(run_accession %in% abun_wide_samples) %>% select(host_disease_status) 
summary(sample_annot_rtPCR)
sample_annot_nuc <- samples %>% filter(run_accession %in% abun_wide_samples) %>% select(nuc) 
summary(sample_annot_nuc)



min_abun <- abun_long %>% filter(fraction_total_reads > 0) %>% summarize(min=min(fraction_total_reads,na.rm = TRUE)) %>% as.numeric 


abun_wide %>% head(100) %>% column_to_rownames(var = "taxon_name") %>% replace(is.na(.), 0) %>% + (min_abun / 2)  %>% mutate_if(is_double,log2) %>% 
  heatmaply(
   xlab='Samples',ylab='taxa',grid_gap=1,
    #scale = "row",
    #colors = colorRampPalette(brewer.pal(3, "RdBu"))(256),
    colors = colorRampPalette(c("white", "orange", "red"))(50),#viridis(n = 256,  option = "magma"),#colorRampPalette(c("white", "red"))(256),gplots::bluered(50)
    #scale_fill_gradient_fun = gradient_col,
    col_side_colors = sample_annot_nuc,
    main = "Oral microbiome diversity in COVID+/- patients",key.title='Abundance',
    plot_method='plotly'#c("ggplot", "plotly"),
  )%>% layout(height=1000,width=800)


abun_wide %>% filter(str_detect(taxon_name, 'virus')) %>% column_to_rownames( var = "taxon_name") %>% replace(is.na(.), 0) %>% + (min_abun / 2)  %>% #mutate_if(is_double,log2) %>% 
  heatmaply(
    k_col = 2, k_row = 2,grid_gap=1,
    #scale = "row",
    #colors = colorRampPalette(brewer.pal(3, "RdBu"))(256),
    colors = colorRampPalette(c("white", "red"))(256),
    #scale_fill_gradient_fun = gradient_col,
    col_side_colors = factor(c(sample_annot_nuc)),
    main = "Oral microbiome diversity in COVID+/- patients",
    plot_method='plotly'#c("ggplot", "plotly"),
  )


heatmaply( mtcars, 
           col_side_colors = c('A','A','B','A','A','A','A','A','A','B','B'),
           plot_method = 'plotly')


#pheatmap is better option



library("heatmaply")
library(tidyverse)
library(DBI)

mydb <- dbConnect(RSQLite::SQLite(), "/shared/projects/form_2022_19/pascal/central_database/sample_collab.db")
abun_long <- as_tibble(dbGetQuery(mydb, "select * from bracken_abundances_long abu left join sample_annot spl using(run_accession);"))
abun_wide <- abun_long %>%  pivot_wider(id_cols = host_subject_id, names_from = taxon_name, values_from = fraction_total_reads) %>% select(1:1500) %>% arrange(host_subject_id)
min_abun  <- abun_long %>% filter(fraction_total_reads > 0) %>% summarize(min=min(fraction_total_reads,na.rm = TRUE)) %>% as.numeric 

abun_wide_hm <- abun_wide %>% column_to_rownames("host_subject_id") %>% replace(is.na(.), 0) %>% + (min_abun / 2)  %>%   mutate_if(is_double,log2)
samples <- dbGetQuery(mydb, 'SELECT * FROM sample_annot order by patient_code;') 
metadata <- samples %>% filter(host_subject_id %in% row.names(abun_wide_hm)) %>% select(host_subject_id,nuc,host_disease_status,host_body_site) %>% arrange(host_subject_id) %>% column_to_rownames("host_subject_id")

heatmaply(abun_wide_hm,
          xlab='Taxa',ylab='Samples',margins=c(5,15,30,10),
          row_side_colors = metadata,showticklabels=FALSE,
          main = "Oral microbiome diversity in COVID+/- patients",
          key.title='Abundance',
          plot_method='plotly'
)
