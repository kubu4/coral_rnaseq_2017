

library(dplyr)
library(ggplot2)

# GOslim categories
ontologies <- c("BP", "CC", "MF")

# Read in first comparsion files
df1 <- read.csv("analyses/20190611_montipora_all_DEG_b_vs_nb_GO/P0.05_C1.bleached-UP.subset.GOseq.enriched.flattened.FDR_1.0.BP.GOslims.csv")

# Read in second comparison file
df2 <- read.csv("analyses/20190611_montipora_all_DEG_b_vs_nb_GO/P0.05_C1.non-bleached-UP.subset.GOseq.enriched.flattened.FDR_1.0.BP.GOslims.csv")


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
df1$treatment <- 'bleached'
df2$treatment <- 'non-bleached'

# Concatenate dataframes
df3 <- rbind(df1, df2)

# Create "pyramid" plot
ggplot(df3, aes(x = Term, fill = treatment, 
                y = ifelse(test = treatment == "bleached", 
                            yes = -Percent, 
                            no = Percent))) + 
  geom_bar(stat = "identity") + 
  scale_y_continuous(labels = abs, limits = max(df3$Percent) * c(-1,1)) + 
  labs(title = "Percentages of GO terms assigned to GOslims", x = "GOslim", y = "Percent GO terms") + 
  scale_x_discrete(expand = c(-1,0)) + 
  coord_flip()
