#!/bin/bash

# Step 1 : QC - Run Fastqc
fastqc /mnt/d/NGS/Samples/P2/Reads/SRR28000175_1.fastq -o /mnt/d/NGS/Samples/P2/Reads/
fastqc /mnt/d/NGS/Samples/P2/Reads/SRR28000175_2.fastq -o /mnt/d/NGS/Samples/P2/Reads/

# Step 2 : Trimming - Run Trimmomatic
trimmomatic PE -phred33 /mnt/d/NGS/Samples/P2/Reads/SRR28000175_1.fastq /mnt/d/NGS/Samples/P2/Reads/SRR28000175_2.fastq /mnt/d/NGS/Samples/P2/Reads/SRR28000175_forward_paired.fastq.gz /mnt/d/NGS/Samples/P2/Reads/SRR28000175_forward_unpaired.fastq.gz /mnt/d/NGS/Samples/P2/Reads/SRR28000175_reverse_paired.fastq.gz /mnt/d/NGS/Samples/P2/Reads/SRR28000175_reverse_unpaired.fastq.gz ILLUMINACLIP:/home/mahdi/mydir/Packages/Trimmomatic-0.39/adapters/TruSeq3-PE.fa:2:30:10:8 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

fastqc /mnt/d/NGS/Samples/P2/Reads/SRR28000175_forward_paired.fastq.gz -o /mnt/d/NGS/Samples/P2/Reads/
fastqc /mnt/d/NGS/Samples/P2/Reads/SRR28000175_reverse_paired.fastq.gz -o /mnt/d/NGS/Samples/P2/Reads/

# Step 3 : Map to reference - Use BWA-MEM
bwa mem -t 6 -R "@RG\tID:SRR2800017\tPL:ILLUMINA\tSM:SRR2800017" /mnt/d/NGS/References/hg38.fa /mnt/d/NGS/Samples/P2/Reads/SRR28000175_forward_paired.fastq.gz /mnt/d/NGS/Samples/P2/Reads/SRR28000175_reverse_paired.fastq.gz > /mnt/d/NGS/Samples/P2/Aligned/SRR28000175.paired.sam
samtools view /mnt/d/NGS/Samples/P2/Aligned/SRR28000175.paired.sam | less
samtools flagstat /mnt/d/NGS/Samples/P2/Aligned/SRR28000175.paired.sam

# Step 4 : Mark Duplicates and Sort - Run GATK4
gatk MarkDuplicatesSpark -I /mnt/d/NGS/Samples/P2/Aligned/SRR28000175.paired.sam -O /mnt/d/NGS/Samples/P2/Aligned/SRR28000175_sorted_dedup.bam
samtools flagstat /mnt/d/NGS/Samples/P2/Aligned/SRR28000175_sorted_dedup.bam

# Step 5 : Base Quality Score Recalibration
gatk BaseRecalibrator -I /mnt/d/NGS/Samples/P2/Aligned/SRR28000175_sorted_dedup.bam -R /mnt/d/NGS/References/hg38.fa --known-sites /mnt/d/NGS/References/resources_broad_hg38_v0_Homo_sapiens_assembly38.dbsnp138.vcf -O /mnt/d/NGS/Samples/P2/Aligned/recal_data.table
gatk ApplyBQSR -I /mnt/d/NGS/Samples/P2/Aligned/SRR28000175_sorted_dedup.bam -R /mnt/d/NGS/References/hg38.fa --bqsr-recal-file /mnt/d/NGS/Samples/P2/Aligned/recal_data.table -O /mnt/d/NGS/Samples/P2/Aligned/SRR28000175_sorted_dedup_bqsr.bam

# Step 6 : Collect Alignment and Insert Size Metrics
gatk CollectAlignmentSummaryMetrics R=/mnt/d/NGS/References/hg38.fa I=/mnt/d/NGS/Samples/P2/Aligned/SRR28000175_sorted_dedup_bqsr.bam O=/mnt/d/NGS/Samples/P2/Aligned/alignment_metrics.txt
gatk CollectInsertSizeMetrics INPUT=/mnt/d/NGS/Samples/P2/Aligned/SRR28000175_sorted_dedup_bqsr.bam OUTPUT=/mnt/d/NGS/Samples/P2/Aligned/insert_size_metrics.txt HISTOGRAM_FILE=/mnt/d/NGS/Samples/P2/Aligned/insert_size_histogram.pdf
multiqc .

# Step 7 : MSI CAlculation
msisensor scan -d /mnt/d/NGS//References/hg38.fa -o /mnt/d/NGS/References/MSIscan.bed
msisensor msi -d /mnt/d/NGS/References/MSIscan.bed -t /mnt/d/NGS/Samples/P2/Aligned/SRR28000175_sorted_dedup_bqsr.bam -o /mnt/d/NGS/Samples/P2/Data/MSIoutput.bed

