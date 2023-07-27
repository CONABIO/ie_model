library(sf)

r_base <- terra::rast('data/sources/hemerobia/raw/2017/hemerobia.tif')

# Create an sf object with the WGS 1984 coordinates (latitude and longitude)
wgs_coords <- st_as_sf(data.frame(lon = c(-94.23, -86.59,
                                          -108.24, -94.23,
                                          -117.89, -103.91,
                                          -103.91, -94.54),
                                  lat = c(14.38, 21.73,
                                          15.06, 22.33,
                                          22.33, 33.04,
                                          22.33, 30.21)),
                       coords = c("lon", "lat"), crs = 4326)


# Define the desired projected coordinate system (here we use EPSG 3857 for Web Mercator)
desired_crs <- crs(r_base)

# Transform the WGS 1984 coordinates to the projected coordinate system (meters)
meters_coords <- st_transform(wgs_coords, crs = desired_crs)

# Print the result
print(meters_coords)