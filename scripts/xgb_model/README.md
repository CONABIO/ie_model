# XGBoost

Se desarrolló un modelo XGBoost para estimar la integridad ecológica, con los siguientes datos:

## Implementación

Se utilizó la paquetería `xgboost` del lenguaje de programación R. Se entrenó el modelo con datos del 2017, a una resolución de 250m para todo el territorio Mexicano. Se puede estimar la integridad ecológica para todo año en el que se tengan datos, con el modelo entrenado para 2017, éste se puede encontrar en la carpeta `models` con el nombre `xgb.fit` y `slic_xgb.fit` para el modelo que usa SLIC.

El flujo de trabajo es el siguiente:

1.  Proyectar cada raster a la misma extención, sistema de coordenadas (epsg) y resolución, mediante el script `scripts/source_extraction/project_raster.R`, que toma un raster de referencia que tiene la exención, epsg y resolución deseada (este se puede encontrar en la carpeta `scripts/source_extraction` con el nombre `Mask_IE2018.tif`). Para proyectar rasters con valores continuos, se utilizó el método `average` (promedio) y para valores categóricos `near` (Nearest neighbor).

2.  Generar el dataframe que será el input del modelo:

    -   Si no se usa SLIC: Transformar los rasters a un dataframe mediante el script `scripts/source_extraction/create_dataframe.R` , el cual recibe el directorio de la carpeta en donde se encuetran los rasters y arroja un dataframe con cada columna con los valores de cada raster y sus respectivas coordenadas geográficas.
    -   Si se usa SLIC: Se crea el shapefile con superpixeles mediante el algoritmo SLIC, con el script `scripts/source_extraction/create_slic.R` , para después extraer el valor de cada raster sobre los superpixeles con `scripts/source_extraction/extract_slic.R`.

    Si se desea entrenar el modelo seguir el paso 3, de lo contrario pasar al 4.

3.  Entrenar el modelo con `xgb_train.r`. Si se tiene una base de datos grande que genera problemas de memoria, utilizar `xgb_train_largeData.R`, que crea una matriz esparcida con los datos y entrena el modelo de forma iterativa.

4.  Predecir el valor de la integridad ecológica con el modelo entrenado y nuevos datos, mediante el script `xgb_predict.R`. Y si se entrenó con matriz esparcida, usar `xgb_predict_largeData.R`.
