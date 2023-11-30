library('tidyverse')
library('xgboost')
library('fastDummies')
library('terra')
library('ggplot2')
library('caret')
library('Matrix')

set.seed <- 1

input_folder <- 'xgboost/data'
output_folder <- 'xgboost/output'
crs_folder <- 'xgboost'

# read data
df <- list.files('xgboost/data', "csv$", full.names = TRUE) %>%
  map_dfr(read_csv) %>% 
  select(-c('holdridge'))
df_hol <- list.files('xgboost/data/holdridge_agg', "csv$", full.names = TRUE) %>%
  map_dfr(read_csv) %>% 
  rename(holdridge = holdridge_agg)
df_edge <- list.files('xgboost/data/edge_distance', "csv$", full.names = TRUE) %>%
  map_dfr(read_csv)
df <- df %>% 
  inner_join(df_hol, by=c('x','y')) %>%
  inner_join(df_edge, by=c('x','y'))
rm(df_hol)
rm(df_edge)

df <- df  %>% 
  mutate(across(all_of(c('hemerobia',
                         'land_cover',
                         'holdridge'
  )), as.factor))

# Split in training and testing stratified by holdridge
train_index <- readRDS(paste0(output_folder,'/train_index.RData'))

df_train <- df[train_index,]
df_test = df[-train_index,]
rm(df)
rm(train_index)

# Create dummy variables
spm_train <- sparse.model.matrix( ~ ., data = df_train %>% 
                                    select(-c('x','y',
                                              'hemerobia')))[,-1]
spm_test <- sparse.model.matrix( ~ ., data = df_test %>% 
                                   select(-c('x','y',
                                             'hemerobia')))[,-1]
label_train <- df_train$hemerobia
label_test <- df_test$hemerobia

# rm(df_test)
# rm(df_train)

# Transform the two data sets into xgb.Matrix
xgb.train <- xgb.DMatrix(data=spm_train,
                         label=as.integer(label_train)-1)

xgb.test <- xgb.DMatrix(data=spm_test,
                        label=as.integer(label_test)-1)


xgb.fit <- xgb.load(paste0(output_folder,'/xgb.fit.20'))

# Predict outcomes with the test data
xgb.pred = as.data.frame(predict(xgb.fit,xgb.test,reshape=T))
colnames(xgb.pred) = levels(df_test$hemerobia)
df_test$prediction <- as.numeric(colnames(xgb.pred)[apply(xgb.pred,1,which.max)])
write.csv(df_test %>% 
            select(x,y,prediction),
          file.path(paste0(output_folder,'/df_test.csv')),
          row.names = FALSE)

df_test <- df_test %>% 
  select(x,y,prediction,hemerobia)

# Predict outcomes with the train data
xgb.pred = as.data.frame(predict(xgb.fit,xgb.train,reshape=T))
colnames(xgb.pred) = levels(df_train$hemerobia)
df_train$prediction <- as.numeric(colnames(xgb.pred)[apply(xgb.pred,1,which.max)])
write.csv(df_train %>% 
            select(x,y,prediction),
          file.path(paste0(output_folder,'/df_train.csv')),
          row.names = FALSE)

df_train <- df_train %>% 
  select(x,y,prediction,hemerobia)

# Create raster
r_pred <- terra::rast(rbind(df_train[,c('x','y','hemerobia')],
                            df_test[,c('x','y','hemerobia')]))
crs_text <- readRDS(paste0(crs_folder,'/crs.RData'))
crs(r_pred) <- crs_text
plot(-r_pred)
writeRaster(r_pred, paste0(output_folder,'/ie_xgb.tif'), 
            overwrite=TRUE)