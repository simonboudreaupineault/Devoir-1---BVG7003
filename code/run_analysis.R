# Analyse de l'expression de REM16 et FT1 selon le sexe chez Cannabis sativa
# (BVG-7003, Devoir 1).
#
# Exécution, depuis la racine du projet :
#   Rscript code/run_analysis.R
# ou, dans RStudio : ouvrir devoir1.Rproj, puis ce fichier, puis cliquer sur « Source ».


# ---- 00. Paramètres (chemins, loci, noms d'affichage, couleurs) ----

# Chemin relatif à la racine du projet. Il est résolu par here::here() à la section 02,
# une fois qu'on a vérifié que le paquet here est installé.
input_dir <- "data"
input_file_name <- "2_Data_RNASeq_Cannabis_Sex.csv"
figures_dir_name <- "figures"
results_dir_name <- "results"
expression_table_name <- "REM16_FT1_expression_long.csv"

# Les gènes sont cherchés par identifiant de locus (non ambigu), mais affichés par leur
# nom usuel dans les messages et les figures.
target_loci <- c(REM16 = "LOC115699937", FT1 = "LOC115696989")

# Le sexe est encodé par le suffixe du nom de colonne (NNN_XX ou NNN_XY).
sex_labels <- c(XX = "Femelle", XY = "Mâle")

# Échantillons exclus en connaissance de cause (justification à la section 04) :
# 011_XX n'a pas de valeur pour FT1, seul NA de tout le fichier.
excluded_samples <- c("011_XX")

# Palette Okabe-Ito : les deux couleurs restent distinguables pour les personnes daltoniennes.
sex_colors <- c(Femelle = "#D55E00", Mâle = "#0072B2")

# Unité de normalisation : inconnue à ce jour (voir CLAUDE.md). À remplacer par l'unité réelle
# dès qu'elle est confirmée dans la source; elle sera affichée sur l'axe Y des figures.
expression_unit <- "unité à confirmer"


# ---- 01. Vérification des paquets ----

required_packages <- c("readr", "dplyr", "tidyr", "ggplot2", "here")

# Le script n'installe rien lui-même : les versions exactes sont fixées dans renv.lock,
# et renv::restore() est la seule façon reproductible de les obtenir.
check_required_packages <- function(packages) {
  is_installed <- vapply(packages, requireNamespace, logical(1), quietly = TRUE)
  missing_packages <- packages[!is_installed]
  if (length(missing_packages) > 0) {
    stop(
      "Paquets manquants : ", paste(missing_packages, collapse = ", "), ".\n",
      "Depuis la racine du projet, exécuter dans R : renv::restore()",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

check_required_packages(required_packages)

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})


# ---- 02. Chargement des données ----

load_expression_data <- function(path) {
  if (!file.exists(path)) {
    stop(
      "Fichier de données introuvable : ", path, "\n",
      "Lancer le script depuis la racine du projet (ou ouvrir devoir1.Rproj dans RStudio) ",
      "et vérifier que le fichier se trouve dans le dossier data/.",
      call. = FALSE
    )
  }
  # Tout est lu comme du texte : la conversion en nombres se fait à la validation (section 03),
  # ce qui permet de repérer une valeur non numérique au lieu de la voir devenir NA en silence.
  expression <- read_csv(
    path,
    col_types = cols(.default = col_character()),
    name_repair = "minimal",
    progress = FALSE
  )
  # La première colonne n'a pas de nom dans le fichier : elle contient les identifiants de gènes.
  names(expression)[1] <- "gene_id"
  expression
}

input_path <- here::here(input_dir, input_file_name)
expression_data <- load_expression_data(input_path)
message(
  "[02] Données chargées : ", nrow(expression_data), " gènes, ",
  ncol(expression_data) - 1, " échantillons."
)


# ---- 03. Validation des données ----

# Retourne le numéro de la ligne du locus. La recherche est ancrée en fin de nom parce que
# REM16 est nommé « Cannabis_LOC115699937 » dans le fichier : une égalité exacte échouerait.
# Le « (^|_) » exige que le locus soit le nom entier ou suive un « _ », pour ne pas
# accepter un identifiant qui le contiendrait au milieu d'un autre nom.
find_locus_row <- function(locus, gene_ids) {
  matches <- grep(paste0("(^|_)", locus, "$"), gene_ids)
  if (length(matches) == 0) {
    stop(
      "Locus ", locus, " introuvable dans la première colonne du fichier.\n",
      "Vérifier l'identifiant dans la section 00 (target_loci).",
      call. = FALSE
    )
  }
  if (length(matches) > 1) {
    stop(
      "Locus ", locus, " trouvé ", length(matches), " fois (",
      paste(gene_ids[matches], collapse = ", "), ").\n",
      "Impossible de savoir quelle ligne utiliser; vérifier le fichier de données.",
      call. = FALSE
    )
  }
  if (gene_ids[matches] != locus) {
    message("[03] Note : ", locus, " est nommé « ", gene_ids[matches], " » dans le fichier.")
  }
  matches
}

# Lit le sexe dans le suffixe du nom de chaque échantillon. Il n'y a pas de fichier de
# métadonnées : un nom mal formé rendrait le sexe inconnu, donc on s'arrête.
extract_sample_sex <- function(sample_ids) {
  duplicated_ids <- unique(sample_ids[duplicated(sample_ids)])
  if (length(duplicated_ids) > 0) {
    stop(
      "Identifiants d'échantillons en double : ", paste(duplicated_ids, collapse = ", "), ".",
      call. = FALSE
    )
  }
  invalid_ids <- sample_ids[!grepl("^[0-9]+_(XX|XY)$", sample_ids)]
  if (length(invalid_ids) > 0) {
    stop(
      "Noms d'échantillons hors du format attendu NNN_XX ou NNN_XY : ",
      paste(invalid_ids, collapse = ", "), ".\n",
      "Le sexe est lu dans ce suffixe; vérifier l'en-tête du fichier de données.",
      call. = FALSE
    )
  }
  sex_codes <- sub("^.*_", "", sample_ids)
  factor(unname(sex_labels[sex_codes]), levels = sex_labels)
}

# Construit un tableau d'une ligne par plante (échantillon, sexe, REM16, FT1). Une valeur
# présente mais impossible à convertir en nombre est une erreur; une valeur absente (NA)
# est conservée ici et traitée à la section 04.
build_target_expression <- function(expression, locus_rows, sample_sex) {
  sample_ids <- names(expression)[-1]
  target_expression <- tibble(sample_id = sample_ids, sex = sample_sex)
  for (gene in names(locus_rows)) {
    raw_values <- unlist(expression[locus_rows[[gene]], -1], use.names = FALSE)
    numeric_values <- suppressWarnings(as.numeric(raw_values))
    non_numeric <- !is.na(raw_values) & is.na(numeric_values)
    if (any(non_numeric)) {
      stop(
        "Valeurs non numériques pour ", gene, " dans les échantillons : ",
        paste(sample_ids[non_numeric], collapse = ", "), ".",
        call. = FALSE
      )
    }
    target_expression[[gene]] <- numeric_values
  }
  target_expression
}

# Signale les valeurs manquantes sans arrêter le script : leur traitement est une décision
# d'analyse, prise et rapportée à la section 04.
report_missing_values <- function(target_expression, genes) {
  for (gene in genes) {
    missing_samples <- target_expression$sample_id[is.na(target_expression[[gene]])]
    if (length(missing_samples) > 0) {
      message(
        "[03] Valeur manquante pour ", gene, " : ",
        paste(missing_samples, collapse = ", "), "."
      )
    }
  }
}

# Résume les effectifs par sexe (p. ex. « Femelle = 69, Mâle = 69 ») pour les messages.
format_sex_counts <- function(sex) {
  counts <- table(sex)
  paste(names(counts), counts, sep = " = ", collapse = ", ")
}

locus_rows <- vapply(target_loci, find_locus_row, integer(1), gene_ids = expression_data$gene_id)
sample_sex <- extract_sample_sex(names(expression_data)[-1])
target_expression <- build_target_expression(expression_data, locus_rows, sample_sex)
report_missing_values(target_expression, names(target_loci))

message("[03] Validation terminée : ", format_sex_counts(sample_sex), ".")


# ---- 04. Correction du problème de qualité ----

# 011_XX n'a pas de valeur pour FT1. On l'exclut de toute l'analyse, REM16 compris, pour
# comparer les deux gènes sur exactement les mêmes plantes (mêmes n dans les trois figures).
# Imputer la valeur aurait inventé une donnée; avec 68 femelles restantes, la perte est minime.
exclude_known_problem_samples <- function(target_expression, samples_to_exclude) {
  absent_samples <- setdiff(samples_to_exclude, target_expression$sample_id)
  if (length(absent_samples) > 0) {
    message(
      "[04] Attention : échantillon(s) à exclure absent(s) du fichier : ",
      paste(absent_samples, collapse = ", "), ". Vérifier excluded_samples (section 00)."
    )
  }
  cleaned_expression <- filter(target_expression, !sample_id %in% samples_to_exclude)
  message(
    "[04] Échantillon(s) exclu(s) : ",
    paste(intersect(samples_to_exclude, target_expression$sample_id), collapse = ", "), ".\n",
    "     Avant : ", nrow(target_expression), " (", format_sex_counts(target_expression$sex), ")\n",
    "     Après : ", nrow(cleaned_expression), " (", format_sex_counts(cleaned_expression$sex), ")"
  )
  cleaned_expression
}

# Après l'exclusion, il ne doit plus rester aucun NA. Un NA restant n'est pas un problème
# connu et documenté : on s'arrête plutôt que de l'exclure en silence.
check_no_missing_values <- function(target_expression, genes) {
  for (gene in genes) {
    missing_samples <- target_expression$sample_id[is.na(target_expression[[gene]])]
    if (length(missing_samples) > 0) {
      stop(
        "Valeur manquante imprévue pour ", gene, " : ",
        paste(missing_samples, collapse = ", "), ".\n",
        "Décider de son traitement, le justifier, puis l'ajouter à excluded_samples (section 00).",
        call. = FALSE
      )
    }
  }
}

cleaned_expression <- exclude_known_problem_samples(target_expression, excluded_samples)
check_no_missing_values(cleaned_expression, names(target_loci))


# ---- 05. Extraction de REM16 et FT1 (format long) ----

# Le tableau d'une ligne par plante a été construit à la section 03 (il fallait les valeurs
# numériques pour les valider). Ici, on le passe en format long (une ligne par plante et par
# gène) : c'est la forme attendue par ggplot2 pour colorer par sexe et facetter par gène.
convert_to_long_format <- function(target_expression, genes) {
  target_expression |>
    pivot_longer(all_of(genes), names_to = "gene", values_to = "expression") |>
    mutate(gene = factor(gene, levels = genes))
}

# Le tableau long est écrit tel quel : c'est exactement ce que reçoit ggplot2, ce qui permet
# de vérifier les valeurs derrière chaque point des figures (contrôle de qualité).
write_expression_table <- function(expression_long, dir_path, file_name) {
  dir.create(dir_path, showWarnings = FALSE)
  output_path <- file.path(dir_path, file_name)
  write_csv(expression_long, output_path)
  # invisible() : renvoie le chemin sans que R l'affiche quand le résultat n'est pas gardé.
  invisible(output_path)
}

expression_long <- convert_to_long_format(cleaned_expression, names(target_loci))
write_expression_table(
  expression_long, here::here(results_dir_name), expression_table_name
)
message(
  "[05] Données extraites : ", nrow(expression_long), " lignes (",
  nrow(cleaned_expression), " plantes x ", length(target_loci), " gènes), écrit dans ",
  file.path(results_dir_name, expression_table_name), "."
)


# ---- 06. Figures individuelles ----

# Étiquettes de sexe avec l'effectif de chaque groupe, p. ex. « Femelle (n = 68) ».
# Les n sont calculés sur les données après correction, jamais écrits en dur.
make_sex_labels_with_n <- function(sex) {
  counts <- table(sex)
  setNames(paste0(names(counts), " (n = ", counts, ")"), names(counts))
}

# Couches communes aux trois figures, pour garantir le même rendu partout.
# - outlier.shape = NA : les valeurs extrêmes sont déjà dessinées par les points
#   individuels; sans cela, elles apparaîtraient deux fois.
# - height = 0 : le jitter est horizontal seulement, les valeurs ne sont pas déformées.
# - seed fixé : les points sont placés de la même façon à chaque exécution.
# - L'axe Y n'est pas forcé à zéro : une boîte à moustaches encode des positions, pas des
#   longueurs, et les deux sexes partagent toujours la même échelle.
plot_expression_by_sex <- function(expression_long, sex_labels_with_n, colors, y_label) {
  ggplot(expression_long, aes(x = sex, y = expression)) +
    geom_boxplot(aes(fill = sex), outlier.shape = NA, alpha = 0.35, width = 0.6) +
    geom_jitter(
      aes(color = sex),
      position = position_jitter(width = 0.15, height = 0, seed = 7003),
      size = 1.6, alpha = 0.8
    ) +
    scale_fill_manual(values = colors, labels = sex_labels_with_n, name = "Sexe") +
    scale_color_manual(values = colors, labels = sex_labels_with_n, name = "Sexe") +
    scale_x_discrete(labels = sex_labels_with_n) +
    labs(x = NULL, y = y_label) +
    theme_bw(base_size = 13)
}

# Une figure par gène. La légende est retirée : l'axe X nomme déjà chaque sexe,
# la couleur n'est donc pas le seul moyen de l'identifier.
save_gene_boxplot <- function(expression_long, gene_name, title, sex_labels_with_n,
                              colors, y_label, output_path) {
  gene_data <- filter(expression_long, gene == gene_name)
  gene_plot <- plot_expression_by_sex(gene_data, sex_labels_with_n, colors, y_label) +
    labs(title = title) +
    theme(
      legend.position = "none",
      plot.title = element_text(face = "bold", hjust = 0.5)
    )
  ggsave(output_path, gene_plot, width = 5, height = 5, dpi = 300)
  output_path
}

figures_dir <- here::here(figures_dir_name)
dir.create(figures_dir, showWarnings = FALSE)

sex_labels_with_n <- make_sex_labels_with_n(cleaned_expression$sex)
y_axis_label <- paste0("Expression normalisée (", expression_unit, ")")

# Les titres sont définis ici, hors des fonctions, pour être réutilisés dans le résumé (08).
individual_figure_titles <- setNames(
  paste("Expression de", names(target_loci), "selon le sexe"), names(target_loci)
)

individual_figure_paths <- vapply(names(target_loci), function(gene_name) {
  save_gene_boxplot(
    expression_long, gene_name, individual_figure_titles[[gene_name]],
    sex_labels_with_n, sex_colors, y_axis_label,
    file.path(figures_dir, paste0(gene_name, "_boxplot_by_sex.png"))
  )
}, character(1))


# ---- 07. Figure combinée ----

# Une facette par gène, avec la même échelle Y : les niveaux d'expression des deux gènes
# se recouvrent (environ 6 à 11), une échelle commune reste donc lisible et évite
# d'agrandir artificiellement les variations du gène le moins variable.
# Ici, la légende est conservée : elle relie les couleurs aux sexes pour les deux facettes.
save_combined_boxplot <- function(expression_long, loci, title, sex_labels_with_n,
                                  colors, y_label, output_path) {
  facet_labels <- setNames(paste0(names(loci), " (", loci, ")"), names(loci))
  combined_plot <- plot_expression_by_sex(expression_long, sex_labels_with_n, colors, y_label) +
    facet_wrap(~gene, labeller = as_labeller(facet_labels)) +
    labs(title = title) +
    theme(
      legend.position = "bottom",
      plot.title = element_text(face = "bold", hjust = 0.5)
    )
  ggsave(output_path, combined_plot, width = 8, height = 5, dpi = 300)
  output_path
}

combined_figure_title <- "Expression de REM16 et FT1 selon le sexe"

combined_figure_path <- save_combined_boxplot(
  expression_long, target_loci, combined_figure_title, sex_labels_with_n,
  sex_colors, y_axis_label,
  file.path(figures_dir, "REM16_FT1_combined_by_sex.png")
)


# ---- 08. Résumé de l'exécution ----

# Le tableau de contrôle est déjà annoncé à la section 05; on liste ici les figures,
# chacune précédée de son titre, avec un chemin relatif à la racine du projet.
figure_titles <- c(individual_figure_titles, combined_figure_title)
figure_paths <- c(individual_figure_paths, combined_figure_path)
relative_figure_paths <- sub(paste0(here::here(), "/"), "", figure_paths, fixed = TRUE)

message(
  "[08] Figures produites :\n",
  paste0("     ", figure_titles, " : ", relative_figure_paths, collapse = "\n")
)
