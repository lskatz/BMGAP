#!/bin/bash 

if [ $# -eq 0 ]; then
  echo "USAGE: $0 R1.fastq.gz R2.fastq.gz outdir/ samplename [HG38 database]"
  exit 0
fi

###################################################
# Definining variables
###################################################
R1=${1}        #R1 fastq
R2=${2}        #R2 fastq
OUT_DIR=${3}   #Sample name directory
NAME=${4}      #Sample name (M#)
HG=hg38
#FASTA_OUT=${5} #FASTA output directory
###################################################

###################################################
# bbmap, clean?
###################################################
clumpify.sh in=$R1 in2=$R2 out=$OUT_DIR/${NAME}_R1_dedup.fastq.gz out2=$OUT_DIR/${NAME}_R2_dedup.fastq.gz dedupe=t

###################################################
# Remove human DNA
###################################################
bowtie2 -p 20 --local -t -x HG38 --un-conc-gz $OUT_DIR/${NAME}_R%_dedup_NoHuman.fastq.gz -1 $OUT_DIR/${NAME}_R1_dedup.fastq.gz -2 $OUT_DIR/${NAME}_R2_dedup.fastq.gz

###################################################
# adapter, and quality trimming, filter for Phred quality 20
###################################################
cutadapt -o $OUT_DIR/${NAME}_R1_dedup_NoHuman_cutTruSeq_trim.fastq.gz -p $OUT_DIR/${NAME}_R2_dedup_NoHuman_cutTruSeq_trim.fastq.gz -n 5 --trim-n -m 50 -q 15 -a Prefix=AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC -A Universal_rc=AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGTAGATCTCGGTGGTCGCCGTATCATT $OUT_DIR/${NAME}_R1_dedup_NoHuman.fastq.gz $OUT_DIR/${NAME}_R2_dedup_NoHuman.fastq.gz

###################################################
# assemble the cleaned PE fastq reads
###################################################
spades.py -t 8 -m 32 --pe1-1 $OUT_DIR/${NAME}_R1_dedup_NoHuman_cutTruSeq_trim.fastq.gz --pe1-2 $OUT_DIR/${NAME}_R2_dedup_NoHuman_cutTruSeq_trim.fastq.gz -o $OUT_DIR/${NAME}_SPAdes

###################################################
echo "Completed alignment of $NAME!"
