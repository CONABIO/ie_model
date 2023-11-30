# XGBoost

Se desarrolló un modelo XGBoost para estimar la integridad ecológica, con los siguientes datos:

| Fuente de datos                             | Variable                                      | Nombre de la variable | Link de descarga                                                                  | Referencia                                     |
|-------------|------------------|--------------|--------|---------------------|
| Hemerobia                                   | Hemerobia                                     | hemerobia             |                                                                                   | Uso de suelo y vegetación, INEGI               |
| Zona de vida de Holdridge                   | Zona de vida de Holdridge                     | holdridge             | <http://www.conabio.gob.mx/informacion/gis/?vns=gis_root/region/fisica/zvh_mx3gw> | Portal de Geoinformación, CONABIO              |
| Elevación (DEM)                             | Elevación promedio                            | dem90_mean            | <https://code.earthengine.google.com/fd44ec12198a21b7f283a86e2f828c15>            | DEM GLO-30, Copernicus                         |
|                                             | Mínimo de elevación                           | dem90_min             |                                                                                   | DEM GLO-30, Copernicus                         |
|                                             | Máximo de elevación                           | dem90_max             |                                                                                   | DEM GLO-30, Copernicus                         |
| Fotosíntesis (Productividad primaria bruta) | Fotosíntesis promedio anual                   | modis_mean            | <https://code.earthengine.google.com/55b24b28652d3a26aa8f5ebc14cc21be>            | Terra Gross Primary Productivity, NASA LP DAAC |
|                                             | Desviación estándar anual de fotosíntesis     | modis_sd              |                                                                                   | Terra Gross Primary Productivity, NASA LP DAAC |
|                                             | Promedio de fotosístesis en estación lluviosa | modis_rainy           |                                                                                   | Terra Gross Primary Productivity, NASA LP DAAC |
|                                             | Promedio de fotosítesis en estación seca      | modis_dry             |                                                                                   | Terra Gross Primary Productivity, NASA LP DAAC |
| Radar (de apertura sintética en la banda C) | Promedio anual de banda VH                    | vh                    | <https://code.earthengine.google.com/fc3284f4477aa1765242f61148991966>            | Sentinel-1, Copernicus Sentinel data           |
|                                             | DE anual de banda VH                          | vh_sd                 |                                                                                   | Sentinel-1, Copernicus Sentinel data           |
|                                             | Entropía del promedio anual de banda VH       | vh_entropy            |                                                                                   | Sentinel-1, Copernicus Sentinel data           |
|                                             | Promedio anual de banda VV                    | vv                    |                                                                                   | Sentinel-1, Copernicus Sentinel data           |
|                                             | DE anual de banda VV                          | vv_sd                 |                                                                                   | Sentinel-1, Copernicus Sentinel data           |
|                                             | Entropía del promedio anual de banda VV       | vv_entropy            |                                                                                   | Sentinel-1, Copernicus Sentinel data           |
| Uso de suelo                                | Uso de suelo                                  | land_cover            | <https://code.earthengine.google.com/d8bac0a4a561e853d004d83c60e41fd3>            | MODIS Land Cover Type, NASA LP DAAC            |

## Implementación

Se utilizó la paquetería `xgboost` del lenguaje de programación R. Se entrenó el modelo con datos del 2017, a una resolución de 250m para todo el territorio Mexicano.

El flujo de trabajo es el siguiente:

1.  Proyectar cada raster a la misma medida (extent), sistema de coordenadas (epsg) y resolución, mediante el script `scripts/source_extraction/project_raster.R`.
2.  Generar el dataframe que será el input del modelo:
    -   Si no se usa SLIC: Transformar los rasters a un dataframe mediante el script `scripts/source_extraction/create_dataframe.R` , el cual recibe el directorio de la carpeta en donde se encuetran los rasters y arroja un dataframe con cada columna con los valores de cada raster y sus respectivas coordenadas geográficas.
    -   Si se usa SLIC: Si se desea utilizar el algoritmo SLIC para crear superpixeles y evitar el efecto sal y pimienta, se puede generar un shapefile con `scripts/source_extraction/create_slic.R` , para después extraer el valor de cada raster sobre los superpixeles con `scripts/source_extraction/``extract_slic.R`
3.  Entrenar el modelo con `xgb_train.r`, si se tiene una base de datos grande, lo que genera problemas de memoria, utilizar `xgb_train_largeData.R`, que genera una matriz esparcida con los datos y entrena el modelo de forma iterativa.
4.  Predecir el valor de la integridad ecológica con el modelo entrenado y nuevos datos, con `xgb_predict.R`, si se entrenó con matriz esparcida usar `xgb_predict_largeData.R`.

Se puede estimar la integridad ecológica para todo año en el que se tengan datos, con el modelo entrenado para 2017, ésta se puede encontrar en la carpeta `model_files` con el nombre `xgb.fit`.
