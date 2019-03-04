

- ```uniprot_porites_P0.05_C1.bleached-UP.subset.csv```: `grep "$(awk '{print $1}' salmon.isoform.counts.matrix.bleached_vs_non-bleached.edgeR.DE_results.P0.05_C1.bleached-UP.subset)" /media/sam/4TB_toshiba/porites/20190129_blastx_ncbi_sp-v5_porites/20190129_blastx_ncbi_sp-v5_porites.tab | awk '{print $2}' | sort -u`

- ```uniprot_porites_P0.05_C1.non-bleached-UP.subset.csv```: `grep "$(awk '{print $1}' salmon.isoform.counts.matrix.bleached_vs_non-bleached.edgeR.DE_results.P0.05_C1.non-bleached-UP.subset)" /media/sam/4TB_toshiba/porites/20190129_blastx_ncbi_sp-v5_porites/20190129_blastx_ncbi_sp-v5_porites.tab | awk '{print $2}' | sort -u`
