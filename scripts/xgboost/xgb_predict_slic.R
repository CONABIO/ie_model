library('tidyverse')
library('xgboost')
library('fastDummies')
library('terra')
library('ggplot2')
library('caret')
library('sf')
library('fasterize')

set.seed <- 1

input_folder <- 'data/model_input/slic'
output_folder <- 'output'
crs_folder <- 'data/model_input/crs'
mask_file <- 'data/sources/mex_mask/Mask_IE2018.tif'

# read data
crs_text <- readRDS(paste0(crs_folder,'/crs.RData'))
df <- read_csv(paste0(input_folder,'/df_xgb_input_slic.csv')) 
sf <- terra::vect(paste0(input_folder,'/slic.shp'))
r_mask <- terra::rast(mask_file)
xgb.fit <- xgb.load(paste0(output_folder,'/xgb slic v3/xgb.fit'))
# df_error <- read_csv(paste0(output_folder,'/error.csv'))

df <- df %>% 
  drop_na()

df <- df  %>% 
  mutate(across(all_of(c('hemerobia',
                         'land_cover',
                         'holdridge'
  )), as.factor))

# Create dummy variables:
df <- dummy_cols(df, select_columns = c('holdridge',
                                        'land_cover'
))

# Split in training and testing stratified by holdridge
# train_index <- readRDS(paste0(output_folder,'/train_index.RData'))
# df_train= df[train_index,] %>% 
#   drop_na()
# df_test = df[-train_index,] %>% 
#   drop_na()
# rm(df)
# rm(train_index)

# Transform the two data sets into xgb.Matrix
# xgb.train <- xgb.DMatrix(data=as.matrix(df_train %>% 
#                                           select(-c('ID','holdridge',
#                                                     'land_cover','hemerobia',
#                                                     'edge_distance'))),
#                          label=as.integer(df_train$hemerobia)-1)
# 
# xgb.test <- xgb.DMatrix(data=as.matrix(df_test %>% 
#                                          select(-c('ID','holdridge',
#                                                    'land_cover','hemerobia',
#                                                    'edge_distance'))),
#                         label=as.integer(df_test$hemerobia)-1)

xgb.matrix <- xgb.DMatrix(data=as.matrix(df %>% 
                                          select(-c('ID','holdridge',
                                                    'land_cover','hemerobia',
                                                    'edge_distance'))),
                         label=as.integer(df$hemerobia)-1)


# Predict outcomes with the test data
# xgb.pred = as.data.frame(predict(xgb.fit,xgb.test,reshape=T))
# colnames(xgb.pred) = levels(df_test$hemerobia)
# df_test$prediction <- as.numeric(colnames(xgb.pred)[apply(xgb.pred,1,which.max)])
# df_test$train <- 0

# Predict outcomes with the train data
# xgb.pred = as.data.frame(predict(xgb.fit,xgb.train,reshape=T))
# colnames(xgb.pred) = levels(df_train$hemerobia)
# df_train$prediction <- as.numeric(colnames(xgb.pred)[apply(xgb.pred,1,which.max)])
# df_train$train <- 1

xgb.pred = as.data.frame(predict(xgb.fit,xgb.matrix,reshape=T))
colnames(xgb.pred) = levels(df$hemerobia)
df$prediction <- as.numeric(colnames(xgb.pred)[apply(xgb.pred,1,which.max)])


# Create raster
# df <- rbind(df_train[,c('ID','prediction','train')],
#             df_test[,c('ID','prediction','train')])

df_aux <- as.data.frame(1:max(df$ID))
names(df_aux) <- 'ID'

df <- df %>% 
  right_join(df_aux) %>% 
  arrange(ID)

sf$prediction <- as.numeric(df$prediction)
# sf$train <- as.numeric(df$train)
  
r_pred <- rasterize(sf, r_mask, field="prediction")
plot(-r_pred)
writeRaster(r_pred, paste0(output_folder,'/ie_xgb_slic_2021.tif'), 
            overwrite=TRUE)

# r_tag <- rasterize(sf, r_mask, field="train")
# plot(r_tag)
# writeRaster(r_tag, paste0(output_folder,'/r_tag.tif'), 
#             overwrite=TRUE)


# Review the final model and results
# xgb.fit
# importance_matrix <- xgb.importance(colnames(xgb.train), 
#                                     model = xgb.fit)
# jpeg(file=paste0(output_folder,"/var_importance.jpeg"),
#      width = 200, height = 150, units='mm', res = 300)
# xgb.plot.importance(importance_matrix = importance_matrix[1:20]) 
# dev.off()
# 
# ggplot(df_error) +
#   geom_line(aes(iter, train_merror), col='blue') +
#   geom_line(aes(iter, test_merror), col='orange')
# ggsave(paste0(output_folder,"/error.png"))