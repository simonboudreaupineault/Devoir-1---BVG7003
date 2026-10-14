# Boxplots de l'expression de REM16 et FT1 selon le sexe.
# À lancer depuis la racine du projet : Rscript question_3/figures_expression.R

library(ggplot2)
library(tidyr)

entree <- "files/2_Data_RNASeq_Cannabis_Sex.csv"
sortie <- "question_3"

# Identifiant de locus -> nom du gène utilisé dans les figures
genes <- c(LOC115699937 = "REM16", LOC115696989 = "FT1")

donnees <- read.csv(entree, row.names = 1, check.names = FALSE)

# Trouve chaque gène par son identifiant (REM16 est nommé "Cannabis_LOC115699937")
lignes <- sapply(names(genes), function(loc) grep(paste0(loc, "$"), rownames(donnees)))
expression <- as.data.frame(t(donnees[lignes, ]))
colnames(expression) <- genes

expression$Sexe <- ifelse(grepl("_XX$", rownames(expression)), "Femelle (XX)", "Mâle (XY)")

# Format long : une ligne par échantillon et par gène
long <- pivot_longer(expression, cols = all_of(unname(genes)),
                     names_to = "Gene", values_to = "Expression")
long$Gene <- factor(long$Gene, levels = genes)
long <- long[!is.na(long$Expression), ]

couleurs <- c("Femelle (XX)" = "#D55E00", "Mâle (XY)" = "#0072B2")
etiquette_y <- "Expression normalisée (log2)"

boxplot_gene <- function(gene) {
  ggplot(long[long$Gene == gene, ], aes(x = Sexe, y = Expression, fill = Sexe)) +
    geom_boxplot(outlier.shape = NA, alpha = 0.6) +
    geom_jitter(width = 0.15, size = 1.5, alpha = 0.7) +
    scale_fill_manual(values = couleurs) +
    labs(title = paste("Expression de", gene, "selon le sexe"),
         x = "Sexe", y = etiquette_y) +
    theme_bw() +
    theme(legend.position = "none")
}

ggsave(file.path(sortie, "boxplot_REM16.png"), boxplot_gene("REM16"),
       width = 5, height = 5, dpi = 300)
ggsave(file.path(sortie, "boxplot_FT1.png"), boxplot_gene("FT1"),
       width = 5, height = 5, dpi = 300)

combinee <- ggplot(long, aes(x = Gene, y = Expression, fill = Sexe)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.6, position = position_dodge(0.8)) +
  geom_point(position = position_jitterdodge(jitter.width = 0.15, dodge.width = 0.8),
             size = 1.2, alpha = 0.7, show.legend = FALSE) +
  scale_fill_manual(values = couleurs) +
  labs(title = "Expression de REM16 et FT1 selon le sexe",
       x = "Gène", y = etiquette_y, fill = "Sexe") +
  theme_bw() +
  theme(legend.position = "top")

ggsave(file.path(sortie, "boxplot_REM16_FT1.png"), combinee,
       width = 7, height = 5, dpi = 300)
