

- ```uniprot_montipora_P0.05_C1.bleached-UP.subset.csv```: `grep "$(awk '{print $1}' salmon.isoform.counts.matrix.bleached_vs_non-bleached.edgeR.DE_results.P0.05_C1.bleached-UP.subset)" /media/sam/4TB_toshiba/montipora/20190129_blastx_ncbi_sp-v5_montipora/20190129_blastx_ncbi_sp-v5_montipora.tab | awk '{print $2}' | sort -u`
