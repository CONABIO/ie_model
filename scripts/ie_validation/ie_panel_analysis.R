# Panel statistics
library('terra')
library('ggplot2')
library('tidyterra')
library('tidyverse')
library("caret")
library('sf')
library('raster')
library('stars')


#### Número de expertos por ANP ####
raster_list <- terra::rast('data/panel_rasters/processed/panel_rasters.tif')
anp_catalog <- read.csv('data/catalog/anp_catalog.csv', encoding = "UTF-8")

df_answers <- as.data.frame(names(raster_list))
names(df_answers) <- "name"
df_answers <- separate_wider_delim(df_answers, 
                                   cols = name, 
                                   delim = "_", 
                                   names = c("type", "class", "expert", "anp"))
df_answers <- df_answers %>% 
  mutate(expert = as.numeric(expert),
         anp = as.numeric(anp))

df_summary <- df_answers %>% 
  filter(anp != 54) %>% 
  group_by(anp) %>% 
  summarise(n = n())

mean(df_summary$n)  
sd(df_summary$n)  
hist(df_summary$n)

#### % del panel respecto a todo el territorio ####
r_panel_agreement_merged <- terra::rast("data/panel_rasters_agreement/processed/panel_rasters_agreement_merged_with_n1.tif")
r_ie <- terra::rast('data/ie/ie_xgb_slic_2023.tif')
plot(r_panel_agreement_merged)

r_panel_agreement_merged <- project(r_panel_agreement_merged, r_ie)
r <- c(r_panel_agreement_merged,r_ie)
df <- terra::as.data.frame(r, xy = TRUE, na.rm = FALSE)
summary(df)

df <- df %>% 
  filter(!is.na(prediction))

sum(!is.na(df$agreement))/nrow(df)

#### % de Integridad alta  ####
r_ie <- terra::rast('data/ie/ie_xgb_slic_2023_4cat.tif')
r_panel_agreement_merged <- terra::rast("data/panel_rasters_agreement/processed/panel_rasters_agreement_merged_with_n1.tif")

r_panel_agreement_merged <- project(r_panel_agreement_merged, r_ie)
r <- c(r_panel_agreement_merged,r_ie)

df <- terra::as.data.frame(c(r_ie, r_panel_agreement_merged), xy = TRUE, na.rm = TRUE)

df$diff <- df$prediction - df$agreement
mean(df$prediction==df$agreement)

hist(df$diff)
table(df$prediction,df$agreement)

df_aux <- df %>% 
  filter(diff!=0)
summary(as.factor(df_aux$diff))/nrow(df_aux)*100

summary(as.factor(df$prediction))
(54906)/nrow(df)
summary(as.factor(df$agreement))
(10876)/nrow(df)

#### pct de coincidencia por ANP ####
r_ie <- terra::rast('data/ie/ie_xgb_slic_2023_4cat.tif')
r_panel <- terra::rast('data//panel_rasters_agreement/processed/panel_rasters_agreement.tif')
anp <- vect('data/anp/186ANP_ITRF08_19012023.shp')
anp_catalog <- read.csv('data/catalog/anp_catalog.csv', encoding = "UTF-8")

raster_files <- list.files('data/panel_rasters/raw/',".tif$",full.names = TRUE)
raster_files <- raster_files[c(39,43,28,20,7,37)]
raster_list <- lapply(raster_files, rast)
raster_list <- lapply(raster_list, project, r_ie, method="near")
raster_list <- lapply(raster_list, subst, from = 0, to = NA)

r_panel <- c(r_panel,raster_list[[1]],raster_list[[2]],raster_list[[3]],
             raster_list[[4]],raster_list[[5]],raster_list[[6]])
names(r_panel)

r <- c(r_ie,r_panel)

df <- data.frame()

for(i in 1:nrow(anp_catalog)){
  anp_name_n <- anp_catalog$anp_name[i]
  print(i)
  print(anp_name_n)
  
  anp_id <- anp_catalog %>% 
    dplyr::filter(anp_name == anp_name_n)
  anp_id <- as.character(anp_id$anp_id)
  
  anp_selected <- subset(anp, anp$NOMBRE == anp_name_n)
  anp_selected <- project(anp_selected, crs(r_ie))
  
  user_rasters_names <- c("prediction",
                          names(r_panel)[gsub("^.*_", "", 
                                              names(r_panel)) == anp_id])
  
  raster_list_anp <- crop(r[[user_rasters_names]], anp_selected,
                          snap = "out",
                          mask=TRUE)
  
  df_raster <- terra::as.data.frame(raster_list_anp,
                                    xy = TRUE, na.rm = FALSE) 
  names(df_raster) <- c("x","y","ie",'panel')
  df_raster$anp <- anp_name_n
  
  df <- rbind(df, df_raster)
}

df_summary <- df %>% 
  filter(!is.na(ie)) %>% 
  group_by(anp) %>% 
  summarise(pct = mean(ie==panel, na.rm=TRUE),
            pct_area = round(mean(!is.na(panel))*100,2))

mean(df_summary$pct)
sd((df_summary$pct))

df_summary <- df %>% drop_na()%>% 
  group_by(anp, ie, panel) %>% 
  summarise(n=n())


#### % con consenso del total de celdas con más de 1 respuesta ####
r_panel <- terra::rast('data/panel_rasters/processed/panel_rasters.tif')
r_panel_agreement <- terra::rast("data/panel_rasters_agreement/processed/panel_rasters_agreement_merged.tif")
# r_panel_agreement <- terra::rast("data/panel_rasters_agreement/processed/panel_rasters_agreement_merged_with_n1.tif")

r_panel_agreement <- project (r_panel_agreement, r_panel)

r <- c(r_panel, r_panel_agreement)
names(r)

df_raster <- terra::as.data.frame(r,
                                  xy = TRUE, na.rm = FALSE)
df_raster$n_ans <- rowSums(!is.na(df_raster[,3:51]))

summary(df_raster %>% 
          filter(n_ans == 0) %>% 
          pull(agreement))
summary(df_raster %>% 
          filter(n_ans == 1) %>% 
          pull(agreement))

df_raster <- df_raster %>% 
  filter(n_ans > 1)

mean(!is.na(df_raster$agreement))

#### distribución de respuestas ####
r_panel <- terra::rast('data/panel_rasters/processed/panel_rasters.tif')
df_raster <- terra::as.data.frame(r_panel,
                                  xy = TRUE, na.rm = FALSE)

df <- df_raster %>%
  pivot_longer(
    cols = starts_with("output"),
    names_to = "user",
    values_to = "answer",
    values_drop_na = TRUE
  )

ggplot(df, aes(x=answer, colour=user)) +
  geom_density() + 
  theme(legend.position = "none")

hist(df$answer)
summary(as.factor(df$answer))/nrow(df)

df_summary <- df %>% 
  group_by(user) %>% 
  summarise(min = min(answer))
summary(as.factor(df_summary$min))/nrow(df_summary)

#### % de orden correcto por ANP ####
# estadísticas por ANP
r_eval <- terra::rast("data/panel_rasters_agreement/processed/panel_rasters_evaluation.tif")
r_ie <- terra::rast('data/ie/ie_xgb_slic_2023_4cat.tif')
anp <- vect('data/anp/186ANP_ITRF08_19012023.shp')
anp_catalog <- read.csv('data/catalog/anp_catalog.csv', encoding = "UTF-8")

df <- data.frame()

for(i in 1:nrow(anp_catalog)){
  anp_name_n <- anp_catalog$anp_name[i]
  print(i)
  print(anp_name_n)
  
  anp_id <- anp_catalog %>% 
    dplyr::filter(anp_name == anp_name_n)
  anp_id <- as.character(anp_id$anp_id)
  
  anp_selected <- subset(anp, anp$NOMBRE == anp_name_n)
  anp_selected <- project(anp_selected, crs(r_ie))
  
  raster_list_anp <- crop(r_eval, anp_selected,
                          snap = "out",
                          mask=TRUE)
  
  df_raster <- terra::as.data.frame(raster_list_anp,
                                    xy = TRUE, na.rm = FALSE) 
  df_raster$anp <- anp_name_n
  
  df <- rbind(df, df_raster)
}

df_summary <- df %>% 
  filter(!is.na(evaluation))
mean(df_summary$evaluation)

df_summary <- df %>% 
  filter(!is.na(evaluation)) %>% 
  group_by(anp) %>% 
  summarise(pct = mean(evaluation))

mean(df_summary$pct)
sd(df_summary$pct)

#### tabla de contingencia IIE vs consenso ####
r_ie <- terra::rast('data/ie/ie_xgb_2023.tif')
r_ie_4cat <- terra::rast('data/ie/ie_xgb_2023_4cat.tif')
r_panel <- terra::rast('data//panel_rasters_agreement/processed/panel_rasters_agreement_merged_with_n1.tif')

r_ie <- project(r_ie, r_panel)
r_ie_4cat <- project(r_ie_4cat, r_panel)
r <- c(r_ie,r_ie_4cat,r_panel)
names(r) <- c('ie','ie_4cat','agreement')

df <- terra::as.data.frame(r,
                           xy = TRUE, na.rm = TRUE) 

contingency_table <- table(as.factor(df$ie_4cat),as.factor(df$agreement))
contingency_table <- contingency_table/rowSums(contingency_table)
contingency_df <- as.data.frame(as.table(contingency_table))
names(contingency_df) <- c("IIE","Consenso","Frecuencia")
contingency_df <- contingency_df %>% 
  mutate(IIE = recode(IIE, "1"="IE Alta",
                      "2"="IE Media",
                      "3"="IE Baja",
                      "4"="IE Muy Baja"),
         Consenso = recode(Consenso, "1"="IE Alta",
                      "2"="IE Media",
                      "3"="IE Baja",
                      "4"="IE Muy Baja"))

# Plot the contingency table as a bar chart
ggplot(contingency_df, aes(x = Consenso, y = IIE, fill = Frecuencia)) +
  geom_tile(color = "white") + # Create squares with borders
  geom_text(aes(label = round(Frecuencia,2)), color = "white", size = 5) +
  scale_fill_gradient(low = "lightblue", high = "darkblue", na.value = "white") +
  # labs(x = "Consenso", y = "IE", fill = "Frecuencia",
  #      title = "Heatmap of Contingency Table") +
  theme_minimal() +
  theme(aspect.ratio = 1) # Ensure the plot is square
