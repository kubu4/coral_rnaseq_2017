#!/bin/env bash



inparanoid_coral_rejects="/media/sam/4TB_toshiba/montipora/20181204_inparanoid/inparanoid_4.1/rejected_sequences.symbB.v1.2.augustus.prot.fa"
trinity_fasta="/media/sam/4TB_toshiba/montipora/20180416_trinity"
trinity_fai="/media/sam/4TB_toshiba/montipora/20180416_trinity.fai"

symbio_trinity_list="symbio-list.txt"
symbio_fasta="symbio-monitpora"

${inparanoid_coral_rejects} \
| tr " " "." \
| tr "(" "." \
| awk -F"." '{ print $5 }' \
> ${symbio_trinity_list}
