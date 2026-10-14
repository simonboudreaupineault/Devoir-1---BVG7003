"""Extrait les données d'expression de REM16 et FT1 du jeu de données RNA-Seq."""

import csv
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
ENTREE = RACINE / "files" / "2_Data_RNASeq_Cannabis_Sex.csv"
SORTIE = RACINE / "question_3" / "expression_REM16_FT1.csv"

# Nom du gène -> identifiant LOC dans le fichier
GENES = {"REM16": "LOC115699937", "FT1": "LOC115696989"}

expression = {}
with open(ENTREE, newline="") as f:
    lecteur = csv.reader(f)
    echantillons = next(lecteur)[1:]
    for ligne in lecteur:
        for nom, loc in GENES.items():
            # endswith, car REM16 est nommé "Cannabis_LOC115699937" dans le fichier
            if ligne[0].endswith(loc):
                expression[nom] = ligne[1:]

with open(SORTIE, "w", newline="") as f:
    ecrivain = csv.writer(f)
    ecrivain.writerow(["Echantillon", "Sexe", *GENES])
    for i, echantillon in enumerate(echantillons):
        sexe = echantillon.split("_")[1]
        ecrivain.writerow([echantillon, sexe, *(expression[nom][i] for nom in GENES)])

print(f"{len(echantillons)} échantillons écrits dans {SORTIE}")
