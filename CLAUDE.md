# CLAUDE.md — Analyse de l'expression de REM16 et FT1 (BVG-7003, Devoir 1)

Versionné volontairement : documente l'encadrement de l'IA pendant le développement.

## Contexte

- Remise : **28 octobre 2026, 13 h (heure du Québec)**.
- Question : l'expression de **REM16** (`LOC115699937`) et de **FT1** (`LOC115696989`) diffère-t-elle
  entre plantes mâles et femelles de *Cannabis sativa* ? Sont-ils des marqueurs candidats du sexe ?
- Données : `data/2_Data_RNASeq_Cannabis_Sex.csv` (46 Mo, versionné).
  - Une ligne par gène (20 500), une colonne par plante (138). 1re colonne = identifiant du gène.
  - Sexe dans le nom des colonnes : `NNN_XX` = femelle (69), `NNN_XY` = mâle (69).
  - Unité de normalisation : **À COMPLÉTER**. Ne jamais la deviner (la plage 4,7–22,8 suggère
    du log2, non confirmé).
- Problèmes de qualité connus :
  1. Seul `NA` du fichier : FT1 pour `011_XX` → exclure `011_XX` de toute l'analyse
     (mêmes plantes pour les deux gènes : 68 F, 69 M). Exclusion rapportée à l'exécution.
  2. REM16 est nommé `Cannabis_LOC115699937` → chercher les loci par regex ancrée en fin de nom
     (`"(^|_)LOC115699937$"`) et vérifier qu'une seule ligne correspond.

## Structure

```
CLAUDE.md, README.md, BVG7003_devoir1.Rproj, renv.lock, renv/, .Rprofile
code/run_analysis.R      # point d'entrée unique
data/2_Data_RNASeq_Cannabis_Sex.csv
figures/                 # sorties générées
question_1/ question_2/ question_4/   # livrables en classe — NE PAS TOUCHER
```

- Ne pas créer de fichiers hors de cette structure sans demander. Ne pas recréer `question_3/`.
- `.gitignore` : `.Rhistory`, `.RData`, `.Rproj.user/`, `renv/library/`, `.DS_Store`.

## Exécution

- `Rscript code/run_analysis.R` depuis la racine, ou *Source* dans RStudio via le `.Rproj`
  (voie conseillée sous Windows).
- Chemins avec `here::here()`; jamais de `setwd()` ni de chemin absolu.
- `renv` pour les dépendances (minimum : readr, dplyr, tidyr, ggplot2, here); `renv::snapshot()`
  à chaque ajout. Le script vérifie les paquets et indique `renv::restore()` sans rien installer.
- R 4.5.3. Le README couvre macOS/Linux et Windows, avec liens officiels R et RStudio.
- Avant tout commit touchant code, données, `renv.lock` ou README : pousser, puis tester
  depuis un clone frais (`git clone https://github.com/simonboudreaupineault/Devoir-1---BVG7003.git`,
  `renv::restore(prompt = FALSE)`, `Rscript code/run_analysis.R`) → les trois figures doivent
  être produites sans intervention.

## Code

- Commentaires en français expliquant le **pourquoi**; noms en anglais, `snake_case`.
- Public : bioinformaticien de premier cycle. Fonctions courtes, lecture de haut en bas.
- Sections : `# ---- 00. Paramètres ----`, `01. Vérification des paquets`, `02. Chargement`,
  `03. Validation`, `04. Correction des problèmes de qualité`, `05. Extraction (format long)`,
  `06. Figures individuelles`, `07. Figure combinée`, `08. Résumé`.

## Validation

Arrêt avec message clair (problème, où, quoi faire) si : fichier absent, locus introuvable ou
en double, sexe hors `XX`/`XY`, valeur non numérique, ou `NA` restant après la section 04.
Aucune exclusion silencieuse : afficher les n avant/après.

## Figures

- `figures/REM16_boxplot_by_sex.png`, `FT1_boxplot_by_sex.png`, `REM16_FT1_combined_by_sex.png`.
- `geom_boxplot(outlier.shape = NA)` + `geom_jitter(height = 0)`.
- n par groupe dans les étiquettes, calculé (pas écrit en dur). Axe Y avec l'unité réelle.
- Pas de troncature d'axe trompeuse. Palette Okabe-Ito, mêmes couleurs partout.
  Combinée : facettes par gène, échelles Y libres signalées.
- `ggsave()` PNG, 300 dpi, dimensions fixes. Pas de test statistique sauf justifié
  (avec taille d'effet).

## Interprétation

Distinguer description (chevauchement des distributions) et conclusion. Ne pas présenter
l'outil comme une méthode de sexage validée. Ne jamais inventer de résultats ni de références.

## Règles pour Claude

- **Interdit** : rédiger, réviser ou suggérer le texte de la vidéo ou de la réflexion sur l'IA
  (règle du cours). Les questions techniques sur le code restent permises.
- Expliquer chaque modification (quoi, pourquoi); changements petits et ciblés.
- Aucun commit ni push sans demande explicite.
- Dans le doute sur les données, demander plutôt que supposer.
- Signaler les erreurs et limites du code, y compris celui de Claude.
