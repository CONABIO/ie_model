library('terra')
library('ggplot2')
library('tidyterra')
library('tidyverse')
library('cowplot')

r_ie_2018 <- terra::rast('data/sources/ie_2018/ie_2018_st_v2.tif')
r_hem <- terra::rast('data/model_input/rasters/hemerobia.tif')
r_xgboost <- terra::rast('output/ie_xgboost.tif')
r_cat <- terra::rast('output/v1/ie_cat.tif')

r_ie_2017<- terra::rast('output/v1/ie_exp.tif')
r_ie_2017_yuc<- terra::rast('output/ie_exp_yuc.tif')
r_hem_2008 <- terra::rast('output/hemerobia_2008.tif')

r_ie_2017 <- terra::project(r_ie_2017, r_ie_2018)
r_cat <- terra::project(r_cat,r_hem)

r_diff <- r_ie_2018 - r_ie_2017
mean_diff <-global(r_diff,mean,na.rm=TRUE)
sd_diff <- global(r_diff,sd,na.rm=TRUE)
hist(values(r_diff))

alpha = 0.10
qnorm(0.5+(alpha/2), mean = 0, sd = 1)
qnorm(0.5-(alpha/2), mean = 0, sd = 1)

range_1 <- sd_diff
range_2 <- 3*sd_diff

r_diff_cat <- classify(r_diff, cbind(-Inf, -range_2, -18), right=FALSE)
r_diff_cat <- classify(r_diff_cat, cbind(-range_2, -range_1, -17), right=FALSE)
r_diff_cat <- classify(r_diff_cat, cbind(-range_1, range_1, 0), right=NA)
r_diff_cat <- classify(r_diff_cat, cbind(range_2, Inf, 18), right=TRUE)
r_diff_cat <- classify(r_diff_cat, cbind(range_1, range_2, 17), right=TRUE)
r_diff_cat <- as.factor(r_diff_cat)
levels(r_diff_cat)

ggplot() +
  geom_spatraster(data = r_diff_cat) +
  scale_fill_manual(values=c("red",
                             "beige",
                             "green"
  ),
  labels=c("Cambio negativo (<-SD)",
           "No hay cambio",
           "Cambio positivo (>SD)"
           )
  )


range_1 <- 3*sd_diff
r_diff_cat <- classify(r_diff, cbind(-Inf, -range_1, -3), right=FALSE)
r_diff_cat <- classify(r_diff_cat, cbind(-range_1, range_1, 0), right=NA)
r_diff_cat <- classify(r_diff_cat, cbind(range_1, Inf, 3), right=TRUE)
r_diff_cat <- as.factor(r_diff_cat)
levels(r_diff_cat)

# writeRaster(r_ie_2017, 'output/r_ie_2017.tif',overwrite=TRUE)
# r_diff_cat <- terra::rast('output/r_diff.tif')

ggplot() +
  geom_spatraster(data = r_diff_cat) +
  scale_fill_manual(values=c("red",
                             "darkred",
                             "beige",
                             "darkgreen",
                             "green"
                             ),
                    labels=c("Cambio negativo mayor",
                              "Cambio negativo (<-SD)",
                              "No hay cambio",
                              "Cambio positivo (>SD)",
                              "Cambio positivo mayor"
                            )
                    )


x <- seq(-1.5, 1.5, 0.1)
plot(x, dnorm(x, mean = 0, sd = sd_diff$sd), type='l')
lines(x, dnorm(x, mean = 0, sd = 0.4), type='l')
lines(x, dnorm(x, mean = 0, sd = 1), type='l')


r_diff <- r_hem - r_cat
range_1 <- 4
r_diff_cat <- classify(r_diff, cbind(-17, -range_1, -18), right=FALSE)
r_diff_cat <- classify(r_diff_cat, cbind(-range_1, range_1, 0), right=NA)
r_diff_cat <- classify(r_diff_cat, cbind(range_1, 17, 18), right=TRUE)
r_diff_cat <- as.factor(r_diff_cat)
ggplot() +
  geom_spatraster(data = r_diff_cat) +
  scale_fill_manual(values = c("darkgreen",
                               "beige",
                               "red"))


coord <- c(3343523, 4083316, 288945.4, 1164515)
coord <- c(2304263, 3218948, 1167037, 3218948)
coord <- c(874873, 2320048, 1167037, 2331944)
coord <- c(1825751, 3343523, 356462.2, 1167037)

plt_hem_2008 <- ggplot() +
  geom_spatraster(data = crop(r_hem_2008,coord)) +
  scale_fill_gradient2(low = "red",
                       mid = "beige",
                       high="darkgreen",
                       midpoint = 0.5)+
  ggtitle('Hemerobia 2008')
plt_hem_2018 <- ggplot() +
  geom_spatraster(data = crop(r_hem,coord)) +
  scale_fill_gradient2(low = "darkgreen",
                       mid = "beige",
                       high="red",
                       midpoint = 9)+
  ggtitle('Hemerobia 2018')

plt_cat <- ggplot() +
  geom_spatraster(data =  crop(r_cat,coord)) +
  scale_fill_gradient2(low = "darkgreen",
                       mid = "beige",
                       high="red",
                       midpoint = 9.0)+
  ggtitle('2017 Cat')

plt_xgb <- ggplot() +
  geom_spatraster(data =  crop(r_xgboost,coord)) +
  scale_fill_gradient2(low = "darkgreen",
                       mid = "beige",
                       high="red",
                       midpoint = 9.0)+
  ggtitle('2017 XGB')

plt_exp <- ggplot() +
  geom_spatraster(data =  crop(r_ie_2017,coord)) +
  scale_fill_gradient2(low = "darkgreen",
                       mid = "beige",
                       high="red",
                       midpoint = 9)+
  ggtitle('2017 Exp')

plt_exp_yuc <- ggplot() +
  geom_spatraster(data =  crop(r_ie_2017_yuc,coord)) +
  scale_fill_gradient2(low = "red",
                       mid = "beige",
                       high="darkgreen",
                       midpoint = 0.5)+
  ggtitle('2017 Exp Yuc')


plt_ie_2018 <- ggplot() +
  geom_spatraster(data =  crop(r_ie_2018,coord)) +
  scale_fill_gradient2(low = "red",
                       mid = "beige",
                       high="darkgreen",
                       midpoint = 0.5)+
  ggtitle('IE 2018')

plot_grid(plt_hem_2018, plt_ie_2018, plt_xgb, plt_cat,
          labels = "AUTO")
ggsave('output/yucatan.jpg')

# df_hem <- read.csv('data/prediction_input/df_input.csv')
# df_cat <- read.csv('output/df_cat.csv')
# df_exp <- read.csv('output/df_exp.csv')

n <- length(values(r_cat))
tab_cat <- table(values(r_cat),values(r_hem))
sum(diag(tab_cat))/n

r_vh <- raster_list[[17]]
r_vh[r_vh < -20] <- NA

df_raster <- terra::as.data.frame(c(raster_list[[4]],raster_list[[14]]),
                                  xy = TRUE, na.rm = TRUE)
r_modis <- terra::rast(df_raster %>% 
             select(x,y,PsnNet))

df_raster <- terra::as.data.frame(c(raster_list[[4]],raster_list[[17]]),
                                  xy = TRUE, na.rm = TRUE)
r_vh <- terra::rast(df_raster %>% 
                         select(x,y,VH))

plt_vh <- ggplot() +
  geom_spatraster(data =  r_vh) +
  scale_fill_gradient2(low = "red",
                       mid = "beige",
                       high="darkgreen",
                       midpoint = -13) +
  ggtitle('VH')

plt_modis <- ggplot() +
  geom_spatraster(data =  r_modis) +
  scale_fill_gradient2(low = "red",
                       mid = "beige",
                       high="darkgreen",
                       midpoint = 200) +
  ggtitle('Modis')

plt_cov <- ggplot() +
  geom_spatraster(data =  raster_list[[14]]) +
  scale_fill_gradient2(low = "darkgreen",
                       mid = "beige",
                       high="red") +
  ggtitle('Asentamientos')

plot_grid(plt_ie_2018, plt_cov, plt_hem_2018,
          plt_exp,
          labels = "AUTO")
ggsave('output/cultivos.png')


df <- list.files('data/model_input/dataframe', full.names = TRUE) %>%
  map_dfr(read_csv)
res <- cor(df)
library(corrplot)
corrplot(res, type = "upper", order = "hclust", 
         tl.col = "black", tl.srt = 90)


library(bnlearn)
df <- read_csv('data/prediction_input/df_input.csv')
input_csv <- 'data/prediction_input/df_input.csv'
col_names <- colnames(read.csv(input_csv, nrows = 1))

df <- read.csv(input_csv,
               skip = 1,
               nrows = 3780659,
               header = FALSE,
               col.names = col_names)
df <- df %>% mutate_if(is.character, as.factor)
df$hemerobia <- as.factor(df$hemerobia)
df$holdridge <- as.factor(df$holdridge)


df_yuc <- read.csv('data/model_input/dataframe/df_input_model_1.csv')
sample <- (sample_n(df_yuc,1000))
plot(sample$x,sample$y)

whitelist <- read.csv('data/model_input/networks/whitelist.csv')
whitelist <- whitelist %>% 
  filter(from!='mad_mex_matorral' & to!='mad_mex_matorral')
df_yuc <- df_yuc %>% mutate_if(is.integer, as.numeric)
network <-hc(df %>% select(-c('x','y','mad_mex_matorral')),
              whitelist = whitelist)
plot(network)

# Fit bayesian network.
df_final <- df %>% 
  select(-c('mad_mex_matorral'))
fitted <- bn.fit(network, data.frame(df_final[,3:ncol(df_final)]), method = "bayes")

# We use the junction tree algorithm to create 
# an independence network that we can query
prior <- compile(as.grain(fitted))
saveRDS(prior, file="data/prediction_input/prior_yuc.RData")
write.csv(df_final,'data/prediction_input/df_input_yuc.csv', row.names = FALSE)
