library('tidyverse')
library('xgboost')
library('fastDummies')
library('terra')
library('ggplot2')
library('caret')

set.seed <- 1

input_folder <- 'data/model_input/dataframe'
output_folder <- 'output'
crs_folder <- 'data/model_input/crs'

# read data
crs_text <- readRDS(paste0(crs_folder,'/crs.RData'))
df <- list.files('xgboost/data', "csv$", full.names = TRUE) %>%
  map_dfr(read_csv) %>% 
  select(-c('holdridge'))
df_hol <- list.files('xgboost/data/holdridge_agg', "csv$", full.names = TRUE) %>%
  map_dfr(read_csv) %>% 
  rename(holdridge = holdridge_agg)
df <- df %>% 
  inner_join(df_hol, by=c('x','y'))
rm(df_hol)

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
train_index <- readRDS(paste0(output_folder,'/train_index.RData'))
df_train= df[train_index,]
df_test = df[-train_index,]
rm(df)
rm(train_index)

# Transform the two data sets into xgb.Matrix
xgb.train <- xgb.DMatrix(data=as.matrix(df_train %>% 
                                          select(-c('x','y','holdridge',
                                                    'land_cover','hemerobia'))),
                         label=as.integer(df_train$hemerobia)-1)

xgb.test <- xgb.DMatrix(data=as.matrix(df_test %>% 
                                         select(-c('x','y','holdridge',
                                                   'land_cover','hemerobia'))),
                        label=as.integer(df_test$hemerobia)-1)


xgb.fit <- xgb.load(paste0(output_folder,'/xgb.fit'))

# Predict outcomes with the test data
xgb.pred = as.data.frame(predict(xgb.fit,xgb.test,reshape=T))
colnames(xgb.pred) = levels(df_test$hemerobia)
df_test$prediction <- as.numeric(colnames(xgb.pred)[apply(xgb.pred,1,which.max)])
write.csv(df_test %>% 
            select(x,y,prediction),
          file.path(paste0(output_folder,'/df_test.csv')),
          row.names = FALSE)

# Predict outcomes with the train data
xgb.pred = as.data.frame(predict(xgb.fit,xgb.train,reshape=T))
colnames(xgb.pred) = levels(df_train$hemerobia)
df_train$prediction <- as.numeric(colnames(xgb.pred)[apply(xgb.pred,1,which.max)])
write.csv(df_train %>% 
            select(x,y,prediction),
          file.path(paste0(output_folder,'/df_train.csv')),
          row.names = FALSE)

# Create raster
r_pred <- terra::rast(rbind(df_train[,c('x','y','prediction')],
                            df_test[,c('x','y','prediction')]))
crs(r_pred) <- crs_text
plot(-r_pred)
writeRaster(r_pred, paste0(output_folder,'/ie_xgb.tif'), 
            overwrite=TRUE)

# Review the final model and results
xgb.fit
importance_matrix <- xgb.importance(colnames(xgb.train), 
                                    model = xgb.fit)
xgb.plot.importance (importance_matrix = importance_matrix[1:20]) 


ggplot(xgb.fit$evaluation_log) +
  geom_line(aes(iter, train_merror), col='blue') +
  geom_line(aes(iter, test_merror), col='orange')


# Accuracy
mean(df_train$prediction==df_train$hemerobia)
mean(df_test$prediction==df_test$hemerobia)

table(df_test$hemerobia, df_test$prediction)
confusionMatrix(df_test$hemerobia, as.factor(df_test$prediction))

df_accuracy_train <- df_train %>% 
  select(holdridge,prediction,hemerobia) %>% 
  group_by(holdridge) %>% 
  summarise(acc_pct = round(mean(prediction == hemerobia)*100,2),
            area_pct = round(n()/nrow(df_train)*100,2))

df_accuracy_test <- df_test %>% 
  select(holdridge,prediction,hemerobia) %>% 
  group_by(holdridge) %>% 
  summarise(acc_pct = round(mean(prediction == hemerobia)*100,2),
            area_pct = round(n()/nrow(df_test)*100,2))