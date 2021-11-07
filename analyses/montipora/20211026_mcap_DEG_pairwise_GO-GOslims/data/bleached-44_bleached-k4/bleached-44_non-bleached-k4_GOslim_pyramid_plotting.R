# Script to generate a "pyramid" plot
# comparing the percentages of enriched GO terms assinged
# to each category of Biological Process GOslims

library(dplyr)
library(ggplot2)


#####################################################
# Set the following variables for the appropriate comparisons/files
#####################################################
# Comparison
## Comparisons need to be separated by an underscore for downstream parsing.
comparison <- "bleached-44_bleached-k4"


######################################################
# CHANGES BELOW HERE ARE PROBABLY NOT NECESSARY
######################################################

# Treatments
## Split comparison into list of two elements
treatments_list <- strsplit(comparison, "_")

## Assign treatments
treatment_01 <- treatments_list[[1]][1]
treatment_02 <- treatments_list[[1]][2]

# Read in first comparsion files
df1 <- read.csv(paste("analyses/",comparison,"/P0.05_C1.", treatment_01, "-UP.subset.GOseq.enriched.flattened.FDR_1.0.BP.GOslims.csv", sep = ""))

# Read in second comparison file
df2 <- read.csv(paste("analyses/", comparison, "/P0.05_C1.", treatment_02, "-UP.subset.GOseq.enriched.flattened.FDR_1.0.BP.GOslims.csv", sep = ""))

# GOslim categories
ontologies <- c("BP", "CC", "MF")

# Remove generic "biological_process" category
df1 <- df1[df1$GOslim != "GO:0008150",]
df2 <- df2[df2$GOslim != "GO:0008150",]

# Remove generic "cellular_component"  category
df1 <- df1[df1$GOslim != "GO:0005575",]
df2 <- df2[df2$GOslim != "GO:0005575",]


# Remove generic "molecular_function"  category
df1 <- df1[df1$GOslim != "GO:0003674",]
df2 <- df2[df2$GOslim != "GO:0003674",]

# Select columns
df1 <- df1 %>% select(Term, Percent)
df2 <- df2 %>% select(Term, Percent)

# Create treatment column and assign term to all rows
df1$treatment <- treatment_01
df2$treatment <- treatment_02

# Concatenate dataframes
df3 <- rbind(df1, df2)

# Filename for plot
pyramid <- paste(comparison, "GOslims", "BP", "png", sep = ".")
pyramid_path <- paste(comparison, pyramid, sep = "/")
pyramid_dest <- file.path("figures", pyramid_path)

# "Open" PNG file for saving subsequent plot
png(pyramid_dest, width = 600, height = 1200, units = "px", pointsize = 12)

# Create "pyramid" plot
ggplot(df3, aes(x = Term, fill = treatment,
                y = ifelse(test = treatment == treatment_01,
                           yes = -Percent,
                           no = Percent))) +
  geom_bar(stat = "identity") +
  scale_y_continuous(labels = abs, limits = max(df3$Percent) * c(-1,1)) +
  labs(title = "Percentages of GO terms assigned to BP GOslims", x = "GOslim", y = "Percent GO terms in GOslim") +
  scale_x_discrete(expand = c(-1,0)) +
  coord_flip()

# Close PNG file
dev.off()
# 