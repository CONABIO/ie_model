library('terra')
library('ggplot2')
library('tidyterra')


IA_cdl_stack_sr <- rast('data/hemerobia2008.tif')
IA_cdl_stack_sr <- rast('data/hemerobia_250m.tif')
crs(IA_cdl_stack_sr)
describe('data/hemerobia2008.tif')
terra::res(IA_cdl_stack_sr)


#pT001D <- project(IA_cdl_stack_sr, "+proj=longlat")

#--- terra::values ---#
values_from_rs <- terra::values(IA_cdl_stack_sr)

#--- take a look ---#
head(values_from_rs) 

df <- data.frame(values_from_rs)

IA_cdl_stack_sr2 <- aggregate(IA_cdl_stack_sr, fact=10)

ggplot() +
  geom_spatraster(data = IA_cdl_stack_sr)
