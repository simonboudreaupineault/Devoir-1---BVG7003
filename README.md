# Devoir 1 — BVG 7003  | Outil d'analyse transcriptomique

## Sommaire

- [Aperçu](#aperçu)
- [Installation](#installation)
- [Exécution](#exécution)
- [Résultats](#résultats)
- [Structure du dépôt](#structure-du-dépôt)

## Aperçu
Ce dépôt contient un outil d'analyse de l'expression génique normalisée de 138 plants de *Cannabis sativa*. Il compare l'expression de deux gènes, **REM16** (LOC115699937) et **FT1** (LOC115696989), entre plants mâles et femelles, afin d'évaluer leur potentiel comme marqueurs candidats du sexe.

Le coeur de l'outil est un script R : `run_analysis.R`. 

Le script permet d'analyser le fichier de données `2_Data_RNASeq_Cannabis_Sex.csv`. 

Le script produit trois graphiques : 

- Boxplot de l'expression de REM16 selon le sexe : `REM16_boxplot_by_sex.png`
- Boxplot de l'expression de FT1 selon le sexe : `FT1_boxplot_by_sex.png`
- Boxplot de l'expression de REM16 et FT1 selon le sexe : `REM16_FT1_combined_by_sex.png`

Les versions des paquets sont fixées avec `renv` et tous les chemins sont relatifs à la racine du projet, pour que l'analyse soit reproductible sur n'importe quel ordinateur ayant cloné le repo depuis **GitHub**.

## Installation

**Prérequis**

- [R](https://cran.r-project.org/)
- [RStudio Desktop](https://posit.co/download/rstudio-desktop/) : Parfois nécessaire pour lancer depuis un ordinateur Windows

**1. Obtenir le dépôt**

```bash
git clone https://github.com/simonboudreaupineault/devoir1_BVG7003.git
cd devoir1_BVG7003
```

**2. Installer les paquets R**

Les versions exactes des paquets sont fixées dans `renv.lock`. La commande `renv::restore()` les
installe dans une bibliothèque propre au projet, sans modifier les autres installations de R.

*macOS et Linux* — dans un terminal, depuis la racine du dépôt :

```bash
Rscript -e 'renv::restore(prompt = FALSE)'
```

*Windows* — `Rscript` n'est généralement pas accessible depuis le terminal, si c'est le cas passer par RStudio :

1. Ouvrir `devoir1.Rproj` (double-clic, ou *File* > *Open Project…* dans RStudio).
2. Dans la console de RStudio, exécuter `renv::restore()` et répondre `y` pour confirmer.

## Exécution

Le script doit être lancé depuis la racine du dépôt (ou via `devoir1.Rproj`).

*macOS et Linux* — dans un terminal, depuis la racine du dépôt :

```bash
Rscript code/run_analysis.R
```

*Windows (via RStudio)* :

1. Ouvrir `devoir1.Rproj`.
2. Ouvrir `code/run_analysis.R`.
3. Cliquer sur *Source* (en haut à droite de l'éditeur).

Les dossiers `figures/` et `results/` sont créés s'ils n'existent pas; les fichiers existants
sont remplacés.

## Résultats



## Structure du dépôt
