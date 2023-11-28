# creates matrix with rows and columns named from data variables

library('tidyverse')

input_file <- 'data/model_input/discretized_df/df_input.csv'
output_file <- 'data/model_input/network/ienet_empty.csv'

# Read only header of data
df <- read.csv(input_file,
               nrows=1)

var_names <- names(df %>% 
                     select(-c('x','y')))

adj_matrix <- data.frame(matrix(0,length(var_names),
                                 length(var_names)))

# set column and row names as file names 
# (dependent and independent variables)
colnames(adj_matrix) <- var_names
rownames(adj_matrix) <- var_names

# write initialized adjacency matrix
write.table(adj_matrix,output_file,sep=",",
            row.names=TRUE,col.names=NA)