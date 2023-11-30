# XGBoost

Se desarrolló un modelo XGBoost para estimar la integridad ecológica, con los siguientes datos:

| Variable                                      | Nombre de la variable | Fuente                                         |
|-----------------------------------------------|-----------------------|------------------------------------------------|
| Hemerobia                                     | hemerobia             | Uso de suelo y vegetación, INEGI               |
| Zona de vida de Holdridge                     | holdridge             | Portal de Geoinformación, CONABIO              |
| Elevación promedio                            | dem90_mean            | DEM GLO-30, Copernicus                         |
| Mínimo de elevación                           | dem90_min             | DEM GLO-30, Copernicus                         |
| Máximo de elevación                           | dem90_max             | DEM GLO-30, Copernicus                         |
| Fotosíntesis promedio anual                   | modis_mean            | Terra Gross Primary Productivity, NASA LP DAAC |
| Desviación estándar anual de fotosíntesis     | modis_sd              | Terra Gross Primary Productivity, NASA LP DAAC |
| Promedio de fotosístesis en estación lluviosa | modis_rainy           | Terra Gross Primary Productivity, NASA LP DAAC |
| Promedio de fotosítesis en estación seca      | modis_dry             | Terra Gross Primary Productivity, NASA LP DAAC |
| Promedio anual de banda VH                    | vh                    | Sentinel-1, Copernicus Sentinel data           |
| DE anual de banda VH                          | vh_sd                 | Sentinel-1, Copernicus Sentinel data           |
| Entropía del promedio anual de banda VH       | vh_entropy            | Sentinel-1, Copernicus Sentinel data           |
| Promedio anual de banda VV                    | vv                    | Sentinel-1, Copernicus Sentinel data           |
| DE anual de banda VV                          | vv_sd                 | Sentinel-1, Copernicus Sentinel data           |
| Entropía del promedio anual de banda VV       | vv_entropy            | Sentinel-1, Copernicus Sentinel data           |
| Uso de suelo                                  | land_cover            | MODIS Land Cover Type, NASA LP DAAC            |
| Distancia al borde                            | edge_distance         |                                                |

## Implementación

Se utilizó la paquetería `xgboost` del lenguaje de programación R. Se entrenó el modelo con datos del 2017, a una resolución de 250m para todo el territorio Mexicano.

Se puede estimar la integridad ecológica para todo año en el que se tengan datos, con el modelo entrenado para 2017, ésta se puede encontrar en la carpeta `model_files` con el nombre `xgb.fit`.

El flujo de trabajo es el siguiente:

1.  Proyectar cada raster a la misma medida (extent), sistema de coordenadas (epsg) y resolución, mediante el script `scripts/source_extraction/project_raster.R`.
2.  Transformar los rasters a un dataframe mediante el script `scripts/source_extraction/create_dataframe.R` , el cual recibe el directorio de la carpeta en donde se encuetran los rasters y arroja un dataframe con cada columna con los valores de cada raster y sus respectivas coordenadas geográficas.
3.  Entrenar el modelo
