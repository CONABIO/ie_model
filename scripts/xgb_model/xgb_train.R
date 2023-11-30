# trains xgb model 

library('tidyverse')
library('xgboost')
library('fastDummies')
library('caret')
library('hardhat')

set.seed <- 1

input_folder <- 'data/model_input/dataframe'
# input_folder <- 'data/model_input/slic' # with SLIC
output_folder <- 'output'
categorical_variables <- c('land_cover',
                           'holdridge')
coordinate_variables <- c('x','y')
# coordinate_variables <- c('ID') # with SLIC

# read data
df <- list.files(input_folder, "csv$", full.names = TRUE) %>%
  map_dfr(read_csv)

df <- df  %>% 
  mutate(across(all_of(c('hemerobia',
                         categorical_variables)), 
                as.factor))

# Create dummy variables:
df <- dummy_cols(df, select_columns = categorical_variables)

# Create partition stratified by holdridge
train_index <- createDataPartition(df$holdridge, p = .7, list = FALSE)
# saveRDS(train_index, file=paste0(output_folder,'/train_index.RData'))
# Save dataframe with partition indicator
df$is_train <- 0
df[train_index[,1],'is_train'] <- 1
write.csv(df %>% 
            select(x, y, is_train), 
          paste0(output_folder,'/is_train.csv'),
          row.names = FALSE)

# Split in training and testing
df_train <- df[train_index,] %>% 
  select(-c('is_train')) %>% 
  drop_na()
df_test <- df[-train_index,] %>% 
  select(-c('is_train')) %>% 
  drop_na()
rm(df)
rm(train_index)

# Transform the two data sets into xgb.Matrix
xgb.train <- xgb.DMatrix(data=as.matrix(df_train %>% 
                                          select(-c(coordinate_variables,
                                                    'hemerobia',
                                                    categorical_variables))),
                         label=as.integer(df_train$hemerobia)-1)

xgb.test <- xgb.DMatrix(data=as.matrix(df_test %>% 
                                         select(-c(coordinate_variables,
                                                   'hemerobia',
                                                   categorical_variables))),
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
  verbose=2
)
# Save model
xgb.save(xgb.fit, paste0(output_folder,'/xgb.fit'))

# Save list of variables
write.csv(colnames(xgb.train), 
          paste0(output_folder,'/variables_list.csv'),
          row.names = FALSE)

# Train and test error
write.csv(as.data.frame(xgb.fit$evaluation_log), 
          paste0(output_folder,'/error.csv'),
          row.names = FALSE)
ggplot(xgb.fit$evaluation_log) +
  geom_line(aes(iter, train_merror), col='blue') +
  geom_line(aes(iter, test_merror), col='orange')
ggsave(paste0(output_folder,"/error.png"))

# Variables importance 
importance_matrix <- xgb.importance(colnames(xgb.train),
                                    model = xgb.fit)
jpeg(file=paste0(output_folder,"/var_importance.jpeg"),
     width = 200, height = 150, units='mm', res = 300)
xgb.plot.importance(importance_matrix = importance_matrix[1:20])
dev.off()