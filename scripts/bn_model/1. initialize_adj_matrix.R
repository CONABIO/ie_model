# Creates empty matrix with rows and columns named after the input data columns

library('tidyverse')

input_file <- 'data/model_input/discretized_df/df_input.csv'
output_file <- 'data/model_input/network/ienet_empty.csv'

# Read only header of data
df <- read.csv(input_file,
               nrows=1)

# Extract names
var_names <- names(df %>% 
                     select(-c('x','y')))

# Create empty matrix
adj_matrix <- data.frame(matrix(0,length(var_names),
                                 length(var_names)))

# Set columns and rows names
colnames(adj_matrix) <- var_names
rownames(adj_matrix) <- var_names

write.table(adj_matrix,output_file,sep=",",
            row.names=TRUE,col.names=NA)