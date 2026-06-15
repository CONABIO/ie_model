# Creates hemerobia raster based on primary vegetation, land use and a catalogue
# of the hemerobia values
library('terra')
library('sf')
library('tidyverse')
library('SpaDES.tools')

r_mask <- terra::rast('scripts/source_extraction/Mask_IE2018.tif') # Mexico mask
s_vp <- st_read('data/other/vegetacion_primaria/vp1mn2.shp')
s_us <- st_read('data/other/serieVII_uso_suelo/usv250s7cw.shp')
df_cat <- read.csv("scripts/hemerobia/hemerobia_catalog.csv",
                   encoding = "UTF-8")

st_crs(s_vp) <- crs(r_mask)
st_crs(s_us) <- crs(r_mask)

raster_splited <- splitRaster(r_mask, nx=10, ny=10)
for (r in 53:100) {
  print(r)
  r_mask_c <- raster_splited[[r]]
  
  if(sum(as.vector(!is.na(r_mask_c))) > 0) {
    s_vp_c <- st_crop(s_vp, r_mask_c)
    s_us_c <- st_crop(s_us, r_mask_c)
    
    # Extract pixel centroids
    coords <- xyFromCell(r_mask_c, 1:ncell(r_mask_c))
    
    # Create an sf object from the coordinates
    points <- st_as_sf(as.data.frame(coords), coords = c("x", "y"), 
                       crs = crs(r_mask_c))
    
    # Filter points in mask
    points$value <- values(r_mask_c)
    names(points) <- c("geometry", "mask")
    points <- points %>% 
      drop_na()
    
    # Get values for each point
    s_vp_points <- st_intersection(s_vp_c[c('TIP_ECOV','TIP_VEG','OTROS')], 
                                   points)
    s_us_points <- st_intersection(s_us_c['DESCRIPCIO'], points)
    sf_data <- st_join(s_vp_points %>% 
                         dplyr::select(-c('mask')), s_us_points) %>% 
      drop_na()
    
    # Join hemerobia value
    sf_data <- sf_data %>% 
      left_join(df_cat, by = c('TIP_ECOV','TIP_VEG',
                               'DESCRIPCIO',
                               'OTROS'))
    
    # Rasterize using the column "value"
    r_hem <- rasterize(vect(sf_data), r_mask_c, field = "HEMEROBIA")
    
    # ggplot() +
    #   geom_spatraster(data=r_hem) 
    
    # Save raster
    writeRaster(r_hem, 
                paste0('data/other/create_hemerobia/new_hemerobia/hemerobia_',
                       r,
                       ".tif"),
                overwrite = T)
  }
}  


# Merge
raster_list <- list.files('data/other/create_hemerobia/new_hemerobia/',".tif$",
                          full.names = TRUE)
r_mask <- terra::rast('scripts/source_extraction/Mask_IE2018.tif') # Mexico mask

raster_list <- lapply(raster_list, rast)
rsrc <- sprc(raster_list)
m <- merge(rsrc)
raster_list <- project(m, r_mask, method="near")
names(raster_list) <- c("HEMEROBIA")
writeRaster(raster_list,
            "data/other/create_hemerobia/new_hemerobia/hemerobia_20251030.tif",
            overwrite=TRUE)

