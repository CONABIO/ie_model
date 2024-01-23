# XGBoost

Se desarrolló un modelo XGBoost para estimar la integridad ecológica, con los siguientes datos:

| Fuente de datos                             | Variable                                      | Nombre de la variable | Link de descarga                                                                  | Referencia                                     |
|---------------------------------------------|-----------------------------------------------|-----------------------|-----------------------------------------------------------------------------------|------------------------------------------------|
| Hemerobia                                   | Hemerobia                                     | hemerobia             |                                                                                   | Uso de suelo y vegetación, INEGI               |
| Zona de vida de Holdridge                   | Zona de vida de Holdridge                     | holdridge             | <http://www.conabio.gob.mx/informacion/gis/?vns=gis_root/region/fisica/zvh_mx3gw> | Portal de Geoinformación, CONABIO              |
| Elevación (DEM)                             | Elevación promedio                            | dem90_mean            | <https://code.earthengine.google.com/b08b9d4d6689d1f30467a230d9c21ea9>            | DEM GLO-30, Copernicus                         |
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

Se utilizó la paquetería `xgboost` del lenguaje de programación R. Se entrenó el modelo con datos del 2017, a una resolución de 250m para todo el territorio Mexicano. XGBoost tuvo un buen ajuste con los parámetros default, solo fueron modificados algunos considerando el número de variables que se tenían, lo parámetros del modelo final fueron:

-   `booster`: gbtree (Default)

-   `eta` learning rate: 0.3 (Default)

-   `gamma` minimum loss reduction required to make a further partition on a leaf node of the tree: 0 (Default)

-   `max_depth` maximum depth of a tree: 10

-   `min_child_weight` minimum sum of instance weight needed in a child: 1 (Default)

-   `subsample` subsample ratio of the training instance: 1 (Default)

-   `colsample_bytree` subsample ratio of columns when constructing each tree: 0.7

    Task parameters

-   `objective` learning task: multi:softprob (predice las probabilidades de que cada punto pertenezca a cada clase)

-   `eval_metric` evaluation metric for validation data: merror (error exacto para modelos de clasificación)

El flujo de trabajo es el siguiente:

1.  Proyectar cada raster a la misma extención, sistema de coordenadas (epsg) y resolución, mediante el script [`scripts/source_extraction/project_raster.R`](../source_extraction/project_raster.R), que toma un raster de referencia que tiene la exención, epsg y resolución deseada (este se puede encontrar en la carpeta [`scripts/source_extraction`](../source_extraction) con el nombre `Mask_IE2018.tif`). Para proyectar rasters con valores continuos, se utilizó el método `average` (promedio) y para valores categóricos `near` (Nearest neighbor).

2.  Generar el dataframe que será el input del modelo:

    -   Si no se usa SLIC: Transformar los rasters a un dataframe mediante el script [`scripts/source_extraction/create_dataframe.R`](../source_extraction/create_dataframe.R) , el cual recibe el directorio de la carpeta en donde se encuetran los rasters y arroja un dataframe con cada columna con los valores de cada raster y sus respectivas coordenadas geográficas.
    -   Si se usa SLIC: Se crea el shapefile con superpixeles mediante el algoritmo SLIC, con el script [`scripts/source_extraction/create_slic.R`](../source_extraction/create_slic.R) , para después extraer el valor de cada raster sobre los superpixeles con [`scripts/source_extraction/extract_slic.R`](../source_extraction/extract_slic.R).

    Si se desea entrenar el modelo seguir el paso 3, de lo contrario pasar al 4.

3.  Entrenar el modelo con `xgb_train.r`. Si se tiene una base de datos grande que genera problemas de memoria, utilizar `xgb_train_largeData.R`, que crea una matriz esparcida con los datos y entrena el modelo de forma iterativa.

4.  Predecir el valor de la integridad ecológica con el modelo entrenado y nuevos datos, mediante el script `xgb_predict.R`. Y si se entrenó con matriz esparcida, usar `xgb_predict_largeData.R`.

Se puede estimar la integridad ecológica para todo año en el que se tengan datos, con el modelo entrenado para 2017, éste se puede encontrar en la carpeta `models` con el nombre `xgb.fit` y `slic_xgb.fit` para el modelo que usa SLIC.
