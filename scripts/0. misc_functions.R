# Load packages
library("bnlearn")
library("gRain")
library("tools")

########## functions used in the Ecological Integrity BN modelling workflow

##### BN specification

# Replace spaces and points by "_", remove file extensions
fixNames = function(string_vector){
  string_vector = file_path_sans_ext(string_vector)
  string_vector = gsub(" ", "_", string_vector)
  string_vector = gsub("\\.", "_", string_vector)
  return(string_vector)
}

# In a matrix:
# fix column and row names
fixDimnames = function(adj_mat){
  colnames(adj_mat)=fixNames(colnames(adj_mat))
  rownames(adj_mat)=fixNames(rownames(adj_mat))
  return(adj_mat)
}

# Initialize empty graph with appropriate node names
# the names are read from the row names of a adjacency matrix
# read from a file (e.g. a csv) or a specified vector
initAdj = function(adj_mat, custom_names=NULL){
  if (is.null(custom_names)){
    bngraph = empty.graph(row.names(adj_mat))
  }
  else{
    bngraph = empty.graph(custom_names)
  }
  return(bngraph)
}

# For a group of nodes set arcs based on a adjacency matrix
setArcs = function(bngraph,
                   adj_mat){
  amat(bngraph) = as.matrix(adj_csv,row.names=TRUE)
  return(bngraph)
}

##### BN fit

# Produce a raster brick where first variable 
# is the dependent variable (Ecological Integrity proxy)
# and the rest independent variables
# All raster are assumed harmonized (same projection, res, extent)
bnBrick = function(dep_path,
                   indep_paths){
  
  bnbrik = brick()
  bnbrik = addLayer(bnbrik,raster(dep_path))
  for (i in 1:length(indep_paths)){
    bnbrik = addLayer(bnbrik,raster(indep_paths[i]))
  }
  return(bnbrik)
}

# Coerce list of integer valued variables to factor
factorCols = function(bnbrik_df,categorical_var_vec){
  for (i in 1:length(categorical_var_vec)){
    bnbrik_df[,
     categorical_var_vec[i]]=as.factor(bnbrik_df[,
                                         categorical_var_vec[i]])
  }
  return(bnbrik_df)
}

# Discretize list of numeric valued variables
discretizeCols = function(bnbrik_df,
                          numeric_var_vec,
                          breaks_vec=rep(5,length(numeric_var_vec)),
                          method="interval"){
  
  bnbrik_df[,numeric_var_vec] = bnlearn::discretize(bnbrik_df[,numeric_var_vec],
                                    breaks=breaks_vec,
                                    method=method)
  return(bnbrik_df)
}
