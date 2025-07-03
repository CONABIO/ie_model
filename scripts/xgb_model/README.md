# XGBoost

Se desarrolló un modelo XGBoost para estimar la integridad ecológica, con los siguientes datos:

| Fuente de datos                             | Variable                                | Nombre de la variable | Link de descarga                                                                     | Referencia                                                                             |
|---------------------------------------------|-----------------------------------------|-----------------------|--------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------|
| Hemerobia                                   | Hemerobia                               | hemerobia             |                                                                                      | Uso de suelo y vegetación, INEGI                                                       |
| Zona de vida de Holdridge                   | Zona de vida de Holdridge               | holdridge             | <http://www.conabio.gob.mx/informacion/gis/?vns=gis_root/region/fisica/zvh_mx3gw>    | Portal de Geoinformación, CONABIO                                                      |
| Elevación (DEM)                             | Elevación promedio                      | dem90_mean            | <https://code.earthengine.google.com/cd45246df07cb1b73549599d64040562>               | DEM GLO-30, Copernicus                                                                 |
|                                             | Mínimo de elevación                     | dem90_min             |                                                                                      | DEM GLO-30, Copernicus                                                                 |
|                                             | Máximo de elevación                     | dem90_max             |                                                                                      | DEM GLO-30, Copernicus                                                                 |
| Fotosíntesis (Productividad primaria bruta) | Fotosíntesis promedio                   | modis_mean            | <https://code.earthengine.google.com/38ca257425a58333e071591d531de13a>               | Terra Gross Primary Productivity, NASA LP DAAC                                         |
|                                             | Desviación estándar de fotosíntesis     | modis_sd              |                                                                                      | Terra Gross Primary Productivity, NASA LP DAAC                                         |
| Radar (de apertura sintética en la banda C) | Promedio de banda VH                    | vh                    | <https://code.earthengine.google.com/72526f0f06c32470907d7b82c641eb42>               | Sentinel-1, Copernicus Sentinel data                                                   |
|                                             | DE de banda VH                          | vh_sd                 |                                                                                      | Sentinel-1, Copernicus Sentinel data                                                   |
|                                             | Entropía del promedio de banda VH       | vh_entropy            |                                                                                      | Sentinel-1, Copernicus Sentinel data                                                   |
|                                             | Suma promedio de banda VH               | vh_savg               |                                                                                      | Sentinel-1, Copernicus Sentinel data                                                   |
|                                             | Promedio anual de banda VV              | vv                    |                                                                                      | Sentinel-1, Copernicus Sentinel data                                                   |
|                                             | DE anual de banda VV                    | vv_sd                 |                                                                                      | Sentinel-1, Copernicus Sentinel data                                                   |
|                                             | Entropía del promedio anual de banda VV | vv_entropy            |                                                                                      | Sentinel-1, Copernicus Sentinel data                                                   |
|                                             | Suma promedio de banda VH               | vv_savg               |                                                                                      | Sentinel-1, Copernicus Sentinel data                                                   |
| Cobertura del suelo                         | Cobertura del suelo                     | land_cover            | <https://code.earthengine.google.com/a7f28385181b4601d41d4a61053c2e47>               | MODIS Land Cover Type, NASA LP DAAC                                                    |
| Distancia al borde                          | Distancia al borde                      | edge_distance         | Se genera con: <https://github.com/CONABIO/ie_model/tree/main/scripts/edge_distance> | MODIS Land Cover Type, NASA LP DAAC  INEGI (2022). Red Nacional de Caminos. RNC. 2022. |


La Zona de vida de Holdridge fue procesada agregando diversas categorías en una sola, con el fin de reducir 31 categorías a 12, de la siguiente manera:

| Nueva categoría | Categoría original | Descripción                                            |
|-----------------|--------------------|--------------------------------------------------------|
| 1               | 1                  | Desierto alvar [Templado - Lluvioso]                   |
|                 | 2                  | Desierto alvar [Templado - Muy Lluvioso]               |
|                 | 3                  | Desierto alvar [Cálido - Muy Lluvioso]                 |
| 2               | 4                  | Desierto Templado Cálido [Templado - Seco]             |
| 3               | 5                  | Desierto Subtropical [Cálido - Seco]                   |
| 4               | 6                  | Tundra Húmeda subalpina [Templado - Lluvioso]          |
|                 | 7                  | Tundra Húmeda alpina [Templado - Subhúmedo]            |
| 5               | 8                  | Estepa Espinosa prermontana [Templado - Seco]          |
|                 | 9                  | Estepa montana [Templado - Seco]                       |
| 6               | 10                 | Matorral Desértico [Cálido - Seco]                     |
|                 | 11                 | Matorral Desértico premontano [Cálido - Seco]          |
|                 | 12                 | Matorral Desértico montano bajo [Templado - Seco]      |
| 7               | 13                 | Bosque Espinoso [Cálido - Seco]                        |
| 8               | 14                 | Bosque Muy Seco [Cálido - Subhúmedo]                   |
| 9               | 15                 | Bosque Seco premontano [Cálido - Subhúmedo]            |
|                 | 16                 | Bosque Seco montano bajo [Templado - Subhúmedo]        |
| 10              | 17                 | Bosque Subhúmedo [Cálido - Lluvioso]                   |
|                 | 18                 | Bosque Subhúmedo premontano [Cálido - Lluvioso]        |
|                 | 19                 | Bosque Subhúmedo montano [Templado - Subhúmedo]        |
|                 | 20                 | Bosque Subhúmedo subalpino [Templado - Seco]           |
|                 | 21                 | Bosque Subhúmedo subalpino [Templado - Subhúmedo]      |
| 11              | 22                 | Bosque Húmedo premontano [Cálido - Lluvioso]           |
|                 | 23                 | Bosque Húmedo montano bajo [Templado - Lluvioso]       |
|                 | 24                 | Bosque Húmedo montano [Templado - Lluvioso]            |
|                 | 25                 | Bosque Húmedo subalpino [Templado - Lluvioso]          |
| 12              | 26                 | Bosque Lluvioso [Cálido - Muy Lluvioso]                |
|                 | 27                 | Bosque Lluvioso premontano [Cálido - Muy Lluvioso]     |
|                 | 28                 | Bosque Lluvioso montano bajo [Cálido - Muy Lluvioso]   |
|                 | 29                 | Bosque Lluvioso montano bajo [Templado - Muy Lluvioso] |
|                 | 30                 | Bosque Lluvioso montano [Cálido - Muy Lluvioso]        |
|                 | 31                 | Bosque Lluvioso montano [Templado - Muy Lluvioso]      |

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

3.  Entrenar el modelo con `xgb_train.r`.

4.  Predecir el valor de la integridad ecológica con el modelo entrenado y nuevos datos, mediante el script `xgb_predict.R`.

Se puede estimar la integridad ecológica para todo año en el que se tengan datos, con el modelo entrenado para 2017, éste se puede encontrar en la carpeta `models` con el nombre `xgb.fit` y `slic_xgb.fit` para el modelo que usa SLIC.
