library(sf)

rast_zone1 <- st_read('data/cosmos_zones/CosmosCompD_BBXS.shp')

rast_zone1$Name
rast_zone1$geometry[3]
plot(rast_zone1)

rast_zone1 <- st_transform(rast_zone1, crs = 4326)
rast_zone1$geometry[3]
