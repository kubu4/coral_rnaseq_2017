_De-novo_ assembly

- Trinity
- 100bp PE
- 379,738,954 reads
- 82.87% overall alignment rate (Bowtie2)
- Contig N50: 756
  - At least 50% of assembled transcripts are at least 756bp
- Median contig length: 361
- Average contig: 580.37
- Total assembled bases: 499,811,373

Identify ORFs

- Transdecoder
- BLASTp longest ORFs against Uniprot/Swissprot database
- HMMR longest ORFs against Pfam-A.hmm database
- Extract complete ORFs
  - 61,306
