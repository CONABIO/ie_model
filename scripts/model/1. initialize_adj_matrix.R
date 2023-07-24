# load packages
library("tools")

# In a matrix:
# fix column and row names
fixDimnames = function(adj_mat){
  colnames(adj_mat)=fixNames(colnames(adj_mat))
  rownames(adj_mat)=fixNames(rownames(adj_mat))
  return(adj_mat)
}
# Replace spaces and points by "_", remove file extensions
fixNames = function(string_vector){
  string_vector = file_path_sans_ext(string_vector)
  string_vector = gsub(" ", "_", string_vector)
  string_vector = gsub("\\.", "_", string_vector)
  return(string_vector)
}

# load misc functions
#source("scripts/0. misc_functions.R")

# List of independent variable rasters file names
var_paths <- list_files_with_exts("data/model_input/rasters",
                                       exts = "tif",
                                       full.names = FALSE)
var_paths

adj_matrix <- data.frame(matrix(0,length(var_paths),
                                 length(var_paths)))

# set column and row names as file names 
# (dependent and independent variables)
colnames(adj_matrix) <- var_paths
rownames(adj_matrix) <- var_paths

# Remove file extensions from dimension names
# Replace "." and spaces with "_"
adj_matrix <- fixDimnames(adj_matrix)

# write initialized adjacency matrix to disk
write.table(adj_matrix,"data/model_input/networks/ienet_empty.csv",sep=",",
            row.names=TRUE,col.names=NA)