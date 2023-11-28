# discretizes numerical data

library('tidyverse')

discretizeCols <- function(bnbrik_df, numeric_var_vec,
                           breaks_vec=rep(5,length(numeric_var_vec)),
                           method="interval"){
  
  bnbrik_df[,numeric_var_vec] = bnlearn::discretize(bnbrik_df[,numeric_var_vec],
                                                    breaks=breaks_vec,
                                                    method=method)
  return(bnbrik_df)
}

input_folder <- 'data/model_input/dataframe'
output_folder <- 'data/model_input/discretized_df'
categorical_var <- c("hemerobia","holdridge")

# read data
df <- list.files(input_folder, "csv$", full.names = TRUE) %>%
  map_dfr(read_csv)

# Transform to factors
df <- df  %>% 
  mutate(across(all_of(categorical_var), as.factor))
df <- discretizeCols(df,setdiff(names(df), c("x","y",categorical_var)))

write.csv(df,paste0(output_folder,'/df_input.csv'), row.names = FALSE)