library(tidyverse)
library(terra)
library(knitr)
library(ggplot2)
library(readxl)
library(broom)

get_test_table <- function(df_counts){
  # Estimate by specie the number of samples, 
  # the difference between Integro and Degradado per sample, 
  # and the mean difference
  df_ei <- df_counts %>% 
    group_by(scientific_name) %>% 
    mutate(n_samples=n(), 
           diff = Integro - Degradado,
           estimate = mean(Integro) - mean(Degradado)) %>% 
    ungroup()
  
  # Estimate number of samples with 
  # the same difference by specie
  df_ei <- df_ei %>% 
    group_by(scientific_name,diff) %>% 
    mutate(n_diff_duplicate = n()) %>% 
    ungroup()
  
  # Run a t-test by specie 
  # which samples have multiple difference values
  # so the variance is greater than zero
  df_test1 <- df_ei %>% 
    filter(!(n_samples==n_diff_duplicate))
  if(nrow(df_test1) > 0) {
    df_test1 <- df_test1 %>% 
      group_by(scientific_name) %>% 
      do(tidy(t.test(.$Integro,
                     .$Degradado, 
                     mu = 0, 
                     alt = "two.sided", 
                     paired = TRUE, 
                     conf.level = 0.95))) %>% 
      mutate(n=parameter+1)
  }
  
  # Only keep the mean difference for species
  # that didn't have variance greater than zero
  df_test2 <- df_ei %>% 
    filter(!(scientific_name %in% df_test1$scientific_name)) %>% 
    group_by(scientific_name, estimate) %>% 
    summarise(n=n())
  
  df_test <- rbind(df_test1,df_test2)
  return(df_test)
}

# IIE maps
r_ei_2021 <- rast('data/ie/ie_xgb_2021.tif')
r_ei_2022 <- rast('data/ie/ie_xgb_2022.tif')
r_ei_2023 <- rast('data/ie/ie_xgb_2023.tif')
r_ei <- c(r_ei_2021, r_ei_2022, r_ei_2023)
r_ei <- project(r_ei, "epsg:4326", method='near')
names(r_ei) <- c('2021', '2022', '2023')

# Ecosystem shapefile
ecor <- vect('data/ecosistemas_sipecam/Ecosist_Biom_sipecam.shp')

# Sipecam data
df <- read_excel("data/Especies Indicadoras IE Sipecam Fototrampeo ENVIADAS.xlsx",
                 "Indicadores positivos")
df <- df %>% 
  mutate_at(vars(date), as.Date, format="%Y-%m-%d") %>% 
  mutate(year = year(date),
         latitude = as.numeric(latitude),
         longitude = as.numeric(longitude),
         sample_code_clean = gsub(":", "_", sample_code),
         cumulo = str_split_i(sample_code_clean, "_", 2),
         nodo = str_split_i(sample_code_clean, "_", 4))

# Iterate by ecosystem
ecor_cat <- unique(values(ecor['Ecosistema']))
for (i in 1:7){
  print(i)
  ecor_value <- ecor_cat[i,1]
  df_ecor <- df
  
  # Crop IIE map with selected ecosystem
  ecor_selected <- subset(ecor, ecor$Ecosistema == ecor_value)
  ecor_selected <- terra::project(ecor_selected, crs(r_ei))
  ie_ecor <- crop(r_ei, ecor_selected, mask=TRUE)
  
  # Add IIE values to sipecam dataframe
  df_coord <- df_ecor %>% 
    select(longitude, latitude)
  df_ie_years <- terra::extract(ie_ecor, 
                 df_coord, 
                 method='exact')
  df_ecor <- cbind(df_ecor, df_ie_years)
  df_ecor$ie_value <- ifelse(df_ecor$year==2021, df_ecor$`2021`,
                             ifelse(df_ecor$year==2022,  df_ecor$`2022`,
                                    df_ecor$`2023`))
  df_ecor$ie <- ifelse(df_ecor$ie_value > 4, 'Degradado', 'Integro')
  df_ecor <- df_ecor %>% 
    drop_na()
  
  # Get counts by cumulo and specie
  df_counts <- df_ecor %>% 
    group_by(cumulo,
             ie,
             scientific_name) %>% 
    summarise(n=n()) %>% 
    spread(ie,n) %>% 
    replace(is.na(.), 0) %>% 
    arrange(scientific_name)
  
  # Add missing column
  if(!'Degradado' %in% names(df_counts)) {
    df_counts <- df_counts %>% add_column(Degradado = 0)
  } 
  if(!'Integro' %in% names(df_counts)) {
    df_counts <- df_counts %>% add_column(Integro = 0)
  } 
  
  # Run paired t test
  df_test_integridad_nodo <- get_test_table(df_counts)
  df_test_integridad_nodo$ecor <- ecor_value
  df_counts$ecor <- ecor_value
  
  if(i==1){
    df_output <- df_test_integridad_nodo
    df_counts_total <- df_counts
  }else{
    df_output <- rbind(df_output,df_test_integridad_nodo)
    df_counts_total <- rbind(df_counts_total,df_counts)
  }
}

df_output <- df_output %>% 
  mutate(ecor = as.factor(ecor)) %>% 
  mutate(ecor = dplyr::recode(ecor, 
                              '1.-  Bosques templados: coníferas / encino' = 'Bosques templados',
                              '2.-  Bosque mesófilo de montaña' = 'Bosque mesófilo de montaña',
                              '3.-  Selva húmeda: alta/mediana/sub&perennifolia' = 'Selva húmeda',
                              '4.-  Selva seca: sub&caducifolia/espinosa' = 'Selva seca',
                              '5.-  Matorral' = 'Matorral',
                              '6.-  Pastizal' = 'Pastizal',
                              '7.- Vegetación hidrófia' = 'Vegetación hidrófia'))

df_plot <- df_output %>% 
  # filter(!is.na(p.value)) # %>% 
  mutate(p.value = ifelse(is.na(p.value),NA,p.value))
ggplot(data=df_plot,
       aes(x=reorder(scientific_name, -estimate), 
           y=estimate,
           fill=estimate>=0)) +
  geom_bar(stat="identity") +
  scale_fill_manual(values = c("#d7191c",'#1a9641'),
                    labels = c("Degradado", 
                               "Íntegro"),
                    name='Más observaciones en:') +
  geom_text(aes(label=paste0(round(estimate,2))), 
            hjust = 0, size = 2.5,
            position = position_dodge(width = 1),
            inherit.aes = TRUE,
            fontface = ifelse(df_plot %>% 
                                pull(p.value) <= 0.05, 2, 1)) +
  ylab('Diferencia de medias (Íntegro - Degradado)') +
  xlab('') +
  coord_flip() +
  theme_classic(base_size = 10) +
  facet_wrap( ~ ecor, nrow = 4, scales = "free")

ggsave(paste0("output/sipecam_positivos.jpg"),
       width = 20, height = 25, units = "cm")
write.csv(df_counts_total,
          "output/counts_sipecam_positivos.csv",
          row.names = F)
write.csv(df_output,
          "output/ttest_sipecam_positivos.csv",
          row.names = F)
write.csv(df %>% 
            select(latitude, longitude, cumulo) %>% 
            distinct(),
          "output/coordenadas_cumulos.csv",
          row.names = F)
