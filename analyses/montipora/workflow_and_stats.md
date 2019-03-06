_De-novo_ assembly

- Trinity
- 100bp PE
- 384,759,598 reads
- 84.64% overall alignment rate (Bowtie2)
- total transcripts 861,176
- Contig N50: 970
  - At least 50% of assembled transcripts are at least 970bp
- Median contig length: 384
- Average contig: 658.25
- Total assembled bases: 566,866,942

Identify ORFs

- Transdecoder
- BLASTp longest ORFs against Uniprot/Swissprot database
    - evalue cutoff <= 1e<sup>-10</sup>
- HMMR longest ORFs against Pfam-A.hmm database
- Complete ORFs
  - 80,852

Identify coral sequences

- BLAST 2.8.1+ (allows for taxonomic searches)
- cnidarians
- BLASTx against NCBI v5 Swissprot database
  - evalue cutoff <= 1e<sup>-04</sup>
  - max_target_seqs=1
- 6,882 unique matches
