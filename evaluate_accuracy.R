# Accuracy
mean(df_train$prediction==df_train$hemerobia)
mean(df_test$prediction==df_test$hemerobia)
df <- rbind(df_train,df_test)
mean(df$prediction==df$hemerobia)

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
