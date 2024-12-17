# Generates edge distance raster based on land cover and roads rasters
library('terra')

r_land_cover <- terra::rast('data/sources/land_cover/processed/2017/land_cover.tif')
r_roads <- terra::rast('data/other/edge_distance/red_vial/red_vial_selected.tif')
mx_mask <-terra::rast('data/sources/mex_mask/Mask_IE2018.tif')  # reference raster

# Assigns value 1 to land cover categories that are not considered to be forest
r_land_cover <- ifel(r_land_cover == 12 |
                       r_land_cover == 13 |
                       r_land_cover == 14, 1, NA)

r_roads <- project(r_roads, mx_mask, method='near')
r_roads <- mask(r_roads, mx_mask)

# Joins land cover and roads map
r_output <- app(sds(r_land_cover, r_roads), fun = "sum", na.rm = TRUE)
r_output <- ifel(r_output == 2 | r_output == 1, 1, NA)

# Calculates the distance from each pixel to the nearest pixel with value 1
distance_raster <- distance(r_output)
distance_raster <- mask(distance_raster, mx_mask)

writeRaster(distance_raster, 
            "data/sources/edge_distance_modis/edge_distance.tif", 
            overwrite=TRUE)
