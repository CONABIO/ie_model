# Red bayesiana

Se desarrolló una red bayesiana para estimar la integridad ecológica, que cuanta con las siguientes capas:

-   Detección de signos: Observaciones obtenidas de sensores remotos.

-   Contextual: Representa las condiciones fisicoquímicas dentro de las cuales, las variables de la capa de detección de signos varían.

-   Latente: Define la condición de la integridad ecológica basándose en los valores de la capa de detección de signos y contextual.

-   Intervención humana: Condiciones provocadas por el ser humano, que podrían afectar la integridad ecológica.

    ![](images/red_resumida_espanol.png)

Se consideraron las siguientes variables

| Variable (nombre en código)                   | Nombre de la variable       | Capa                | Fuente                                         |
|--------------------------|--------------|--------------|------------------|
| Hemerobia                                     | hemerobia                   | Latente             | Uso de suelo y vegetación, INEGI               |
| Proporción de cultivos y pastizales           | mad_mex_cultivos_pastizales | Intervención humana | MAD-Mex, CONABIO                               |
| Proporción de asentamientos humanos           | mad_mex_asentamientos       | Intervención humana | MAD-Mex, CONABIO                               |
| Proporción de suelo desnudo                   | mad_mex_suelo_desnudo       | Intervención humana | MAD-Mex, CONABIO                               |
| Zona de vida de Holdridge                     | holdridge                   | Contextual          | Portal de Geoinformación, CONABIO              |
| Elevación promedio                            | dem90_mean                  | Contextual          | Continuo de Elevaciones Mexicano, INEGI        |
| Mínimo de elevación                           | dem90_min                   | Contextual          | Continuo de Elevaciones Mexicano, INEGI        |
| Máximo de elevación                           | dem90_max                   | Contextual          | Continuo de Elevaciones Mexicano, INEGI        |
| Fotosíntesis promedio anual                   | modis_mean                  | Detección de signos | Terra Gross Primary Productivity, NASA LP DAAC |
| Desviación estándar anual de fotosíntesis     | modis_sd                    | Detección de signos | Terra Gross Primary Productivity, NASA LP DAAC |
| Promedio de fotosístesis en estación lluviosa | modis_rainy                 | Detección de signos | Terra Gross Primary Productivity, NASA LP DAAC |
| Promedio de fotosítesis en estación seca      | modis_dry                   | Detección de signos | Terra Gross Primary Productivity, NASA LP DAAC |
| Proporción de matorral                        | mad_mex_matorral            | Detección de signos | MAD-Mex, CONABIO                               |
| Proporsión de selva                           | mad_mex_selva               | Detección de signos | MAD-Mex, CONABIO                               |
| Proporción de bosque                          | mad_mex_bosque              | Detección de signos | MAD-Mex, CONABIO                               |
| VH                                            | vh                          | Detección de signos | Sentinel-1, Copernicus Sentinel data           |
| VH entropía                                   | vh_entropy                  | Detección de signos | Sentinel-1, Copernicus Sentinel data           |

## Implementación

Se utilizó la paquetería `bnlearn` del lenguaje de programación R. Se entrenó la red con datos del 2017, a una resolución de 250m para todo el territorio Mexicano.

Se puede estimar la integridad ecológica para todo año en el que se tengan datos, con la red entrenada para 2017, ésta se puede encontrar en la carpeta `model_files` con el nombre `prior.RData`. También se encuentra la matriz de adjacencia con la que se creó la red `ienet.csv`.

El flujo de trabajo es el siguiente:

1.  Proyectar cada raster a la misma medida (extent), sistema de coordenadas (epsg) y resolución, mediante el script `scripts/source_extraction/project_raster.R`.

2.  Transformar los rasters a un dataframe, mediante el script `scripts/source_extraction/create_dataframe.R` , el cual recibe el directorio de la carpeta en donde se encuetran los rasters y arroja un dataframe cuyas columnas contienen los valores de cada raster y sus respectivas coordenadas geográficas.

3.  Se consideró una red bayesiana discreta, por lo que las variables continuas tienen que ser convertidas a categóricas mediante el script `0. discretize_df.R`.

    Si se desea entrenar una red bayesiana seguir el paso 4 y 5, de lo contrario pasar al 6.

4.  Crear una matriz de adyacencia. El script `1. initialize_adj_matrix.R`, recibe el csv creado en el paso 3 y crea una matriz cuyos nombres de cada renglón y columna corresponden al nombre de cada variable. Una vez creada, ésta puede ser manipulada en otro software, como Excel, para ser llenada con 1's donde existe un arco entre las variables. La dirección del arco es renglón ---\> columna.

5.  El `script 3. fit_model` recibe el dataframe y la matriz de adyacencia para entrenar la red bayesiana, guardando la red ya entrenada.

6.  Con el script `4. predict_with_bn` se puede predecir la integridad ecológica, obteniendo un raster, mediante una red ya entrenada y con datos generados siguiendo del paso 1 al 3.
