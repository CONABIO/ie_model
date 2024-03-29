# Red bayesiana

Se desarrolló una red bayesiana para estimar la integridad ecológica, que cuanta con las siguientes capas:

-   Detección de signos: Observaciones obtenidas de sensores remotos.

-   Contextual: Representa las condiciones fisicoquímicas dentro de las cuales, las variables de la capa de detección de signos varían.

-   Latente: Define la condición de la integridad ecológica basándose en los valores de la capa de detección de signos y contextual.

-   Intervención humana: Condiciones provocadas por el ser humano, que podrían afectar la integridad ecológica.

    ![](images/red_resumida_espanol.png)

Se consideraron las siguientes variables

| Fuente de datos                             | Variable                                      | Nombre de la variable       | Capa                | Link de descarga                                                                  | Referencia                                     |
|---------------------------------------------|-----------------------------------------------|-----------------------------|---------------------|-----------------------------------------------------------------------------------|------------------------------------------------|
| Hemerobia                                   | Hemerobia                                     | hemerobia                   | Latente             |                                                                                   | Uso de suelo y vegetación, INEGI               |
| Uso de suelo (MAD-Mex)                      | Proporción de cultivos y pastizales           | mad_mex_cultivos_pastizales | Intervención humana | <https://madmex.conabio.gob.mx>                                                   | MAD-Mex, CONABIO                               |
|                                             | Proporción de asentamientos humanos           | mad_mex_asentamientos       | Intervención humana |                                                                                   |                                                |
|                                             | Proporción de suelo desnudo                   | mad_mex_suelo_desnudo       | Intervención humana |                                                                                   |                                                |
|                                             | Proporción de matorral                        | mad_mex_matorral            | Detección de signos |                                                                                   |                                                |
|                                             | Proporsión de selva                           | mad_mex_selva               | Detección de signos |                                                                                   |                                                |
|                                             | Proporción de bosque                          | mad_mex_bosque              | Detección de signos |                                                                                   |                                                |
| Zona de vida de Holdridge                   | Zona de vida de Holdridge                     | holdridge                   | Contextual          | <http://www.conabio.gob.mx/informacion/gis/?vns=gis_root/region/fisica/zvh_mx3gw> | Portal de Geoinformación, CONABIO              |
| Elevación (DEM)                             | Elevación promedio                            | dem90_mean                  | Contextual          | <https://code.earthengine.google.com/b08b9d4d6689d1f30467a230d9c21ea9>            | Continuo de Elevaciones Mexicano, INEGI        |
|                                             | Mínimo de elevación                           | dem90_min                   | Contextual          |                                                                                   |                                                |
|                                             | Máximo de elevación                           | dem90_max                   | Contextual          |                                                                                   |                                                |
| Fotosíntesis (Productividad primaria bruta) | Fotosíntesis promedio anual                   | modis_mean                  | Detección de signos | <https://code.earthengine.google.com/55b24b28652d3a26aa8f5ebc14cc21be>            | Terra Gross Primary Productivity, NASA LP DAAC |
|                                             | Desviación estándar anual de fotosíntesis     | modis_sd                    | Detección de signos |                                                                                   |                                                |
|                                             | Promedio de fotosístesis en estación lluviosa | modis_rainy                 | Detección de signos |                                                                                   |                                                |
|                                             | Promedio de fotosítesis en estación seca      | modis_dry                   | Detección de signos |                                                                                   |                                                |
| Radar (de apertura sintética en la banda C) | VH                                            | vh                          | Detección de signos | <https://code.earthengine.google.com/fc3284f4477aa1765242f61148991966>            | Sentinel-1, Copernicus Sentinel data           |
|                                             | VH entropía                                   | vh_entropy                  | Detección de signos |                                                                                   |                                                |

## Implementación

Se utilizó la paquetería `bnlearn` del lenguaje de programación R. Se entrenó la red con datos del 2017, a una resolución de 250m para todo el territorio Mexicano. El flujo de trabajo es el siguiente:

0.  Para extraer las variables de la fuente Uso de suelo (MAD-Mex) utilizar el script [`scripts/source_extraction/extract_mad_mex.R`](../source_extraction/extract_mad_mex.R).

1.  Proyectar cada raster a la misma extensión, sistema de coordenadas (epsg) y resolución, mediante el script [`scripts/source_extraction/project_raster.R`](../source_extraction/project_raster.R), que toma un raster de referencia que tiene la exención, epsg y resolución deseada (este se puede encontrar en la carpeta [`scripts/source_extraction`](../source_extraction) con el nombre `Mask_IE2018.tif`). Para proyectar rasters con valores continuos, se utilizó el método `average` (promedio) y para valores categóricos `near` (Nearest neighbor).

2.  Transformar los rasters a un dataframe, mediante el script [`scripts/source_extraction/create_dataframe.R`](../source_extraction/create_dataframe.R) , el cual recibe el directorio de la carpeta en donde se encuetran los rasters y arroja un dataframe cuyas columnas contienen los valores de cada raster y sus respectivas coordenadas geográficas.

3.  Se consideró una red bayesiana discreta, por lo que las variables continuas tienen que ser convertidas a categóricas mediante el script `0. discretize_df.R`.

    Si se desea entrenar una red bayesiana seguir el paso 4 y 5, de lo contrario pasar al 6.

4.  Crear una matriz de adyacencia. El script `1. initialize_adj_matrix.R`, recibe el csv creado en el paso 3 y crea una matriz cuyos nombres de cada renglón y columna corresponden al nombre de cada variable. Una vez creada, ésta puede ser manipulada en otro software, como Excel, para ser llenada con 1's donde existe un arco entre las variables. La dirección del arco es renglón ---\> columna.

5.  El `script 2. fit_model` recibe el dataframe y la matriz de adyacencia para entrenar la red bayesiana, guardando la red ya entrenada.

6.  Con el script `3. predict_with_bn` se puede predecir la integridad ecológica, mediante una red ya entrenada y con datos generados siguiendo del paso 1 al 3, obteniendo un archivo csv con las coordenadas y su respectivo valor.

7.  Mediante `4. create_ie_raster.R` se puede generar el raster de integridad ecológica con el csv del paso anterior.

Se puede estimar la integridad ecológica para todo año en el que se tengan datos, con la red entrenada para 2017, ésta se puede encontrar en la carpeta [`model_files`](./model_files) con el nombre `prior.RData`. También se encuentra la matriz de adjacencia con la que se creó la red, con el nombre `ienet.csv`.
