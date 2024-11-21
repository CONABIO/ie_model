# Trains XGBoost classification model for ecological integrity estimation

library('tidyverse')
library('xgboost')
library('fastDummies')
library('caret')
library('hardhat')

set.seed <- 1

# ======================Input============================
input_folder <- 'data/model_input/slic/2017'
output_folder <- 'output/models/xgb slic v11'
categorical_variables <- c('holdridge',
                           'land_cover')
# remove_variable <- c('edge_distance')
remove_variable <- c('')

# coordinate_variables <- c('x','y')
coordinate_variables <- c('ID') # if SLIC is used

# ==================Processing data======================
df <- list.files(input_folder, "csv$", full.names = TRUE) %>%
  map_dfr(read_csv)

df <- df  %>% 
  select_if(!names(.) %in% remove_variable) %>%
  drop_na() %>% 
  mutate(across(all_of(c('hemerobia',
                         categorical_variables)), 
                as.factor))

# Add missing level in land cover
levels(df$land_cover) <- c(levels(df$land_cover),3)
df$land_cover <- factor(df$land_cover, 
                        levels=1:17)

# Create dummies for categorical
df <- dummy_cols(df, select_columns = categorical_variables)

# Create partition stratified by holdridge
# 70% for training and 30% for testing
train_index <- createDataPartition(df$holdridge, p = .7, list = FALSE)

# Save csv with coordinates and indicator 
# (1=training data point, 0=testing data point)
df_is_train <- df %>% 
  select(all_of(coordinate_variables))
df_is_train$is_train <- 0 
df_is_train[train_index[,1],'is_train'] <- 1
write.csv(df_is_train, 
          paste0(output_folder,'/is_train.csv'),
          row.names = FALSE)

# Split in training and testing
df_train <- df[train_index,]
df_test <- df[-train_index,]
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

# ======================Training model============================
# Define the parameters
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
  nrounds=2000,
  early_stopping_rounds=10,
  watchlist=list(train=xgb.train,test=xgb.test),
  verbose=2
)

# =====================Saving output===========================
# Save model
xgb.save(xgb.fit, paste0(output_folder,'/xgb.fit'))

# Save list of input variables
write.csv(colnames(xgb.train), 
          paste0(output_folder,'/variables_list.csv'),
          row.names = FALSE)

# Save train and test error
write.csv(as.data.frame(xgb.fit$evaluation_log), 
          paste0(output_folder,'/error.csv'),
          row.names = FALSE)
ggplot(xgb.fit$evaluation_log) +
  geom_line(aes(iter, train_merror), col='blue') +
  geom_line(aes(iter, test_merror), col='orange')
ggsave(paste0(output_folder,"/error.png"))

# Save variables importance 
importance_matrix <- xgb.importance(colnames(xgb.train),
                                    model = xgb.fit)
jpeg(file=paste0(output_folder,"/var_importance.jpeg"),
     width = 200, height = 150, units='mm', res = 300)
xgb.plot.importance(importance_matrix = importance_matrix[1:20])
dev.off()