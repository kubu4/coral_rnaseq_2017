library(GSEABase)
library(tidyverse)

# Script to retrieve GOslims from Trinity-based, EdgeR GOseq differential gene expression.
# Identifies enriched and depleted output files.
# Requires "goslim_generic.obo" from http://geneontology.org/docs/go-subset-guide/

### Create list of files
goseq_files <- list.files(path = "./data",
                          pattern = "\\.GOseq.[de]",
                          full.names = TRUE)

### Set output filename suffix
output_suffix=("GOslims.csv")

### Strip path from goseq files
goseq_filename <- basename(goseq_files)



for (item in goseq_files) {
  
  ## Get max number of fields
  # Needed to handle reading in file with different number of columns in each row
  max_fields <- max(count.fields(item, sep = "\t"))
  
  ## Read in tab-delimited GOseq file
  # Use "max_fields" to populate all columns with a sequentially numbered header
  go_seqs <- read.table(item,
                        sep = "\t",
                        header = TRUE,
                        col.names = paste0("V",seq_len(max_fields)),
                        fill = TRUE)
  
  ## Grab just the individual GO terms from the "category" column)
  goterms <- as.character(go_seqs$V1)
  
  ### Use GSEA to map GO terms to GOslims
  
  ## Store goterms as GSEA object
  myCollection <- GOCollection(goterms)
  
  ## Use generic GOslim file to create a GOslim collection
  
  # I downloaded goslim_generic.obo from http://geneontology.org/docs/go-subset-guide/
  # then i moved it to the R library for GSEABase in the extdata folder
  # in addition to using the command here - I think they're both required.
  slim <- getOBOCollection("./data/goslim_generic.obo")
  
  ## Map GO terms to GOslims and select Biological Processes group
  slims <- goSlim(myCollection, slim, "BP", verbose = TRUE)
  
  
  ### Prep output file naming structure
  
  ## Split filenames on periods
  ## Creates a list
  split_filename <- strsplit(item, ".", fixed = TRUE)
  
  ## Slice split_filename list from position 9 to the last position of the list
  ## Paste these together using a period
  goseq_filename_split <-paste(split_filename[[1]][9:lengths(split_filename)], collapse = ".")
  
  ## Paste elements together to form output filename
  outfilename <- paste(goseq_filename_split, output_suffix, collapse = ".", sep = ".")
  
  # Set output file destination and name
  outfile_dest <- file.path("./analyses/", outfilename)
  
  ## Write output file
  # write.csv(slims, file = outfile_dest, quote = FALSE)
  
  
}