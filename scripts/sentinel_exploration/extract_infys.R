library(tidyverse)

xmin <- -99.45069
ymin <- 18.79024 
xmax <- -98.85816
ymax <- 19.13412

df_infys <- read.csv("data/infys/INFYS_Arbolado_2015_2020.csv", 
                     fileEncoding="latin1")

df_infys_arb <- df_infys %>% 
  #filter(X_C3>=xmin & X_C3<=xmax &
  #         Y_C3>=ymin & Y_C3<=ymax) %>% 
  filter((AlturaTotal_C3!=999993) & 
           (Forma_Biologica_Cat_C3!='NULL')
         ) %>% 
  filter(Forma_Biologica_Cat_C3 == 'Arbol') %>%
  #filter(DiametroCopa_C3<100000) %>% 
  group_by(X_C3,Y_C3) %>% 
  summarise(Altura_mean = mean(AlturaTotal_C3),
            Altura_median = median(AlturaTotal_C3),
            Altura_min = min(AlturaTotal_C3),
            Altura_max = max(AlturaTotal_C3),
            Altura_sd = sd(AlturaTotal_C3),
            Diametro_median = median(DiametroCopa_C3),
            n=n()
            )

df_infys_arb$Diametro_median <- ifelse(df_infys_arb$Diametro_median>100000,NA,
                       df_infys_arb$Diametro_median)

df_infys_arb$plot_id <- 1:nrow(df_infys_arb) 

# write.csv(df_infys_arb %>%
#             select(X_C3,Y_C3,plot_id),
#           'data/infys/infys_coordinates.csv',
#           row.names = FALSE)