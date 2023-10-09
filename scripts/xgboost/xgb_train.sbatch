#!/bin/bash
#
#SBATCH -J xgbtrain_ie
#SBATCH -o output.txt
#SBATCH -e output.err
#SBATCH --export ALL
#SBATCH -w nodo[5,7],keri

train_file=xgb_train.R

echo "Lanzando "$train_file
Rscript $train_file