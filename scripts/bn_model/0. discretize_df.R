# Discretizes numerical data to serve as input for a Bayesian network

library('tidyverse')
library('bnlearn')

input_folder <- 'data/model_input/dataframe'
output_folder <- 'data/model_input/discretized_df'
categorical_variables <- c("hemerobia","holdridge")

# Read data
df <- list.files(input_folder, "csv$", full.names = TRUE) %>%
  map_dfr(read_csv)

df <- df  %>% 
  mutate(across(all_of(categorical_variables), as.factor))

numerical_variables <- setdiff(names(df), c("x","y",categorical_variables))

# Define 5 categories for each numerical column
breaks_vec <- rep(5,length(numerical_variables))
# Transform numerical columns to categorical
df[,numerical_variables] <- bnlearn::discretize(df[,numerical_variables],
                                                breaks = breaks_vec,
                                                method = 'interval')


write.csv(df,paste0(output_folder,'/df_input.csv'), row.names = FALSE)