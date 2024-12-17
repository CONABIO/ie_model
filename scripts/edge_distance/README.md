# Distancia al borde

La distancia al borde se define como la distancia de cada pixel al borde del bosque. Para su construcción, primero se genera un mapa de *bosque/no bosque*, para lo cual se utilizó la cobertura de suelo de MODIS de la banda Land Cover Type 1 (Friedl, M. et al, 2022), considerando como *no bosque* a las categorías 12 (tierras de cultivo), 13 (terrenos urbanos y edificados) y 14 (mosaicos de tierras de cultivo y vegetación natural) . Este mapa se unió con el de la Red Nacional de Caminos RNC. 2022 (INEGI, 2022), del cual se consideraron las siguientes categorías como *no bosque:*

| Categoría        | Considerada como *no bosque*? |
|------------------|-------------------------------|
| Ampliación       | Sí                            |
| Andador          | No                            |
| Avenida          | Sí                            |
| Boulevard        | Sí                            |
| Calle            | Sí                            |
| Callejón         | No                            |
| Calzada          | Sí                            |
| Camino           | Sí                            |
| Carretera        | Sí                            |
| Circuito         | Sí                            |
| Circunvalación   | Sí                            |
| Continuación     | Sí                            |
| Corredor         | Sí                            |
| Diagonal         | Sí                            |
| Eje vial         | Sí                            |
| Enlace           | Sí                            |
| Glorieta         | Sí                            |
| Pasaje           | No                            |
| Peatonal         | No                            |
| Periférico       | Sí                            |
| Privada          | No                            |
| Prolongación     | Sí                            |
| Rampa de frenado | No                            |
| Retorno          | No                            |
| Vereda           | No                            |
| Viaducto         | Sí                            |
| Otro             | No                            |

Una vez creado el mapa de *bosque/no bosque,* se estima la distancia de cada pixel al pixel más cercano cuya categoría es *no bosque,* por lo que cultivos, terrenos urbanos y caminos tendrán un valor de cero.

INEGI (2022). Red Nacional de Caminos. RNC. 2022.

Friedl, M., Sulla-Menashe, D. (2022). *MODIS/Terra+Aqua Land Cover Type Yearly L3 Global 500m SIN Grid V061* [Data set]. NASA EOSDIS Land Processes Distributed Active Archive Center. Accessed 2024-12-17 from <https://doi.org/10.5067/MODIS/MCD12Q1.061>
