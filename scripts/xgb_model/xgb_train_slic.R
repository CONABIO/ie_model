library('tidyverse')
library('xgboost')
library('fastDummies')
library('terra')
library('ggplot2')
library('caret')

set.seed <- 1

input_folder <- 'data/model_input/slic'
output_folder <- 'output'

# read data
df <- read_csv(paste0(input_folder,'/df_xgb_input_slic.csv'))

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
train_index <- createDataPartition(df$holdridge, p = .7, list = FALSE)
saveRDS(train_index, file=paste0(output_folder,'/train_index.RData'))

df_train <- df[train_index,] %>% 
  drop_na()
df_test <- df[-train_index,] %>% 
  drop_na()
rm(df)
rm(train_index)

# Transform the two data sets into xgb.Matrix
xgb.train <- xgb.DMatrix(data=as.matrix(df_train %>% 
                                          select(-c('ID','holdridge',
                                                    'land_cover','hemerobia'))),
                         label=as.integer(df_train$hemerobia)-1)

xgb.test <- xgb.DMatrix(data=as.matrix(df_test %>% 
                                         select(-c('ID','holdridge',
                                                   'land_cover','hemerobia'))),
                        label=as.integer(df_test$hemerobia)-1)


# Define the parameters for multinomial classification
params <- list(
  booster="gbtree",
  objective="multi:softprob",
  eta=0.3,
  gamma=0,
  max_depth=10,
  min_child_weight=1,
  subsample=1,
  colsample_bytree=0.7,
  eval_metric="merror",
  num_class=length(levels(df_train$hemerobia))
)

# Train the XGBoost classifer
xgb.fit <- xgb.train(
  params=params,
  data=xgb.train,
  nrounds=1000,
  early_stopping_rounds=10,
  watchlist=list(train=xgb.train,test=xgb.test),
  save_period=10,
  verbose=2
)
xgb.save(xgb.fit, paste0(output_folder,'/xgb.fit'))
write.csv(as.data.frame(xgb.fit$evaluation_log), 
          paste0(output_folder,'/error.csv'),
          row.names = FALSE)