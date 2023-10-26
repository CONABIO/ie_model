library('tidyverse')
library('xgboost')
library('fastDummies')
library('terra')
library('ggplot2')
library('caret')
library('Matrix')

set.seed <- 1

input_folder <- 'data/model_input/dataframe'
output_folder <- 'output'

# read data
df <- list.files(input_folder, "csv$", full.names = TRUE) %>%
  map_dfr(read_csv) 

df <- df  %>% 
  mutate(across(all_of(c('hemerobia',
                         'land_cover',
                         'holdridge'
  )), as.factor))

# Split in training and testing stratified by holdridge
train_index <- createDataPartition(df$holdridge, p = .7, list = FALSE)
saveRDS(train_index, file=paste0(output_folder,'/train_index.RData'))

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

rm(df_test)
rm(df_train)

# Transform the two data sets into xgb.Matrix
xgb.train <- xgb.DMatrix(data=spm_train,
                         label=as.integer(label_train)-1)

xgb.test <- xgb.DMatrix(data=spm_test,
                        label=as.integer(label_test)-1)


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
  num_class=length(levels(label_train))
)

xgb.fit.new <- xgb.fit

for (i in 1:10){
  xgb.fit.new <- xgb.train(
    params=params,
    data=xgb.train,
    xgb_model=xgb.fit,
    nrounds=20,
    early_stopping_rounds=10,
    watchlist=list(train=xgb.train,test=xgb.test),
    save_period=2,
    verbose=2
  )
  xgb.save(xgb.fit, paste0(output_folder,'/xgb.fit'))
  write.csv(as.data.frame(xgb.fit$evaluation_log), 
            paste0(output_folder,'/error_',i,'.csv'),
            row.names = FALSE)
}