library('tidyverse')

# Discretize list of numeric variables wder
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
remove_var <- c('')

# read data
df <- list.files(input_folder, "csv$", full.names = TRUE) %>%
  map_dfr(read_csv)

# Remove unwanted variables
df <- df[,!(names(df) %in% remove_var)]

# Transform to factors
df <- df  %>% 
  mutate(across(all_of(c("hemerobia","holdridge")), as.factor))
df <- discretizeCols(df,setdiff(names(df), c("x","y",
                                             "hemerobia","holdridge")))

write.csv(df,paste0(output_folder,'/df_input.csv'), row.names = FALSE)