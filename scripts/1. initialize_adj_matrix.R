# load packages
library("tools")

# load misc functions
source("./R/0. misc_functions.R")

# List of independent variable rasters file names
indep_var_paths = list_files_with_exts("./indep_var_paths/",
                                       exts = "tif",
                                       full.names = FALSE)
indep_var_paths
# File name of dependent variable raster to be used
dep_var_file = "hemerobia_250m.tif"

adj_matrix = data.frame(matrix(0,length(indep_var_paths)+1,
                                 length(indep_var_paths)+1))

# set column and row names as file names 
# (dependent and independent variables)
colnames(adj_matrix)=c(dep_var_file,indep_var_paths)
rownames(adj_matrix)=c(dep_var_file,indep_var_paths)

# Remove file extensions from dimension names
# Replace "." and spaces with "_"
adj_matrix = fixDimnames(adj_matrix)

# write initialized adjacency matrix to disk
write.table(adj_matrix,"./networks/ienet_empty_v2.csv",sep=",",
            row.names=TRUE,col.names=NA)
