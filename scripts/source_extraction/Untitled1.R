r_hem_2017 <- terra::rast('data/sources/hemerobia/raw/2017/hemerobia.tif')
r_hem_2008 <- terra::rast('data/sources/hemerobia/raw/2008/hemerobia.tif')

val_hem_2017 <- values(r_hem_2017)
values(r_hem_2017) <- (18-val_hem_2017)/18

ggplot() +
  geom_spatraster(data = r_hem_2008)
ggplot() +
  geom_spatraster(data = r_hem_2017)

r_diff <- diff(c(r_hem_2017,r_hem_2008))
ggplot() +
  geom_spatraster(data = r_diff)
