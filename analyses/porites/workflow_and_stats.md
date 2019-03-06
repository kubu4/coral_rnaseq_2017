_De-novo_ assembly


- Trinity
- 100bp PE
- 379,738,954 reads
- 82.87% overall alignment rate (Bowtie2)
- Contig N50: 756
  - i.e. At least 50% of assembled transcripts are at least 756bp
- Median contig length: 361
- Average contig: 580.37
- Total assembled bases: 499,811,373

Identify ORFs

- Transdecoder
- BLASTp longest ORFs against Uniprot/Swissprot database
  - evalue cutoff <= 1e<sup>-10</sup>
- HMMR longest ORFs against Pfam-A.hmm database
- Extract complete ORFs
  - 61,306

Identify coral sequences

- BLAST 2.8.1+
- cnidarians
- BLASTx against NCBI v5 Swissprot database
  - evalue cutoff <= 1e<sup>-04</sup>
  - max_target_seqs=1
- 5,838 unique matches

Differential gene expression

- salmon (transcript abundance)
- edgeR (differential expression - via Trinity utility scripts)
- Bleached, upregulated
  - p-value <= 0.05
  - > 2-fold expression
  - 4 genes

- Unbleached, upgregulated
  - p-value <= 0.05
  - > 2-fold expression
  - 11 genes
