# ChRDPETpipeline
Processing chromatin associated RNA-DNA interactions followed by paired-end-tag sequencing (ChRD-PET) data <br/>
This pipeline consists of three scripts. <br/>
1) run.sh: 
- Splitting data into DNA and RNA data.
- DNA data alignment to the genome by bwa. RNA data alignment to the genome by hisat2 and bowtie2.
- Extracting the uniq aligned reads.
2) run.coverage.sh: 
- Convert bam file to BigWig file.
- Generate some profile result.
3) run.interaction.sh:
- Merge DNA-RNA interaction according to read ID
- Extraction of high-confidence DNA-RNA interactions using hypergeometric distribution test

REQUIREMENTS
============
1) java8
2) python
3) perl
4) R

1) samtools
2) bowtie2 (bowtie2.2 best)
3) hisat2
4) bwa
5) [flash](http://ccb.jhu.edu/software/FLASH/)
6) cutadapt
7) bedtools
8) deeptools
9) HTSeq


Building index
==============
I converted both "Chr" and "ChR0" to "chr" and gff files to gtf files.
```
wget http://rice.hzau.edu.cn/rice_rs1/download_ext/MH63RS1.LNNK00000000.fsa.tar.gz
wget http://rice.hzau.edu.cn/rice_rs1/download_ext/MH63_chr.gff.tar.gz
wget http://rice.hzau.edu.cn/rice_rs1/download_ext/MH63_repeat.gff3.tar.gz

bwa index genome.fa
grep -v ">" genome.fa | perl -lane '{$_=~s/[Nn]+//g;$sum+=length($_);}END{print $sum;}' # genome length

python hisat2-2.1.0/extract_splice_sites.py genome.gtf > genome.ss
python hisat2-2.1.0/extract_exons.py genome.gtf > genome.exon
hisat2-build -p 8 --ss genome.ss --exon genome.exon genome.fa genome
bowtie2-build --threads 8 genome.fa genome

perl -F"\t" -lane 'if($F[2] eq "gene"){$gene=$1 if($F[8]=~/gene_id "(.+?)";/);$type="coding";$name=$gene;print "$F[0]\t".($F[3]-1)."\t$F[4]\t$name\t0\t$F[6]\t$gene\t$type"}' genome.gtf > genome.info
or
perl -lane 'if($F[2] eq "gene"){$tmp=(split(/;/,$F[8]))[0];$gene=(split(/=/,$tmp))[1];print "$F[0]\t".($F[3]-1)."\t$F[4]\t$gene\t.\t$F[6]"}' genome.gff3 | awk '{print $0"\t"$4"\coding"}' > genome.info

get rrna region: 
    get rrna region from MH63_repeat.gff3.tar.gz file (grep "rRNA").
```

Usage of ChRDPETpipeline
=======================
```
bash run.sh
# mv outfile.DNA.bam outfile.DNA.old.bam && intersectBed -a outfile.DNA.old.bam -b all.rrna.region.bed -v > outfile.DNA.bam
# mv outfile.RNA.bam outfile.RNA.old.bam && intersectBed -a outfile.RNA.old.bam -b all.rrna.region.bed -v > outfile.RNA.bam
bash run.coverage.sh
bash run.interaction.sh
# If your annotation file is in gff format. Please rewrite  "-i gene_id" to "-i ID" in run.interaction.sh file.
```

Output files
============
```
run.sh result:
*.DNA.fastq # the DNA reads
*.RNA.fastq # the RNA reads
*.DNA.bam # the DNA reads align result
*.RNA.bam # the RNA reads align result

run.coverage.sh result: 
*.bw # visualization in IGV
*.RNA.sense.richheatmap.cg.pdf # Just a quick look at, a few regions that need to be eliminated with unusually high expression

run.interaction.sh result: 
*.DNARNA.givenanchor.FDRfiltered.txt # interaction. visualization in IGV 
```

My tools version
============
```
java8(1.8.0_161)    python(3.7.9)       perl(v5.26.2)       R(3.5.2)
samtools(1.9)       bowtie2(2.3.5.1)    hisat2(2.1.0)       bwa(0.7.15-r1140)
flash(v1.2.11)      cutadapt(2.3)       bedtools(v2.27.1)   deeptools(3.2.1)
HTSeq(0.11.2)
```

contact me: huang182@live.cn/huangxingyu@webmail.hzau.edu.cn/1182768992@qq.com