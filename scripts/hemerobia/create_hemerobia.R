# Creates hemerobia raster based on primary vegetation, land use and a catalog
# of the hemerobia values
library('terra')
library('sf')
library('tidyverse')
library('stars')

r_mask <- terra::rast('scripts/source_extraction/Mask_IE2018.tif') # Mexico mask
s_vp <- st_read('data/other/vegetacion_primaria/vp1mn1.shp')
s_us <- st_read('data/other/serieVII_uso_suelo/usv250s7cw.shp')
df_cat <- read.csv("scripts/hemerobia/hemerobia_catalog.csv")

st_crs(s_vp) <- crs(r_mask)
st_crs(s_us) <- crs(r_mask)

# Extract pixel centroids
coords <- xyFromCell(r_mask, 1:ncell(r_mask))

# Create an sf object from the coordinates
points <- st_as_sf(as.data.frame(coords), coords = c("x", "y"), crs = crs(r_mask))

# Filter points in mask
points$value <- values(r_mask)
names(points) <- c("geometry", "mask")
points <- points %>% 
  drop_na()

# Get values for each point
s_vp_points <- st_intersection(s_vp[c('TIP_ECOV')], points)
s_us_points <- st_intersection(s_us['DESCRIPCIO'], points)
sf_data <- st_join(s_vp_points %>% 
                     dplyr::select(-c('mask')), s_us_points)

# Join hemerobia value
sf_data <- sf_data %>% 
  left_join(df_cat, by = c("TIP_ECOV","DESCRIPCIO"))

# Create raster
r_hem <- st_rasterize(sf_data %>% 
                        dplyr::select(c('hemerobia','geometry'))
)

# Save raster
write_stars(r_hem, 
            'data/hemerobia.tif')