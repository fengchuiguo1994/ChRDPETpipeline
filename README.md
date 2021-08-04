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
```
bwa index genome.fa
python hisat2-2.1.0/extract_splice_sites.py genome.gtf > genome.ss
python hisat2-2.1.0/extract_exons.py genome.gtf > genome.exon
hisat2-build -p 8 --ss genome.ss --exon genome.exon genome.fa genome
bowtie2-build --threads 8 genome.fa genome
perl -F"\t" -lane 'if($F[2] eq "gene"){$gene=$1 if($F[8]=~/gene_id "(.+?)";/);$type="coding";$name=$gene;print "$F[0]\t".($F[3]-1)."\t$F[4]\t$name\t0\t$F[6]\t$gene\t$type"}' genome.gtf > genome.info
grep -v ">" genome.fa | perl -lane '{$_=~s/[Nn]+//g;$sum+=length($_);}END{print $sum;}' # genome length
```

Usage of ChRDPETpipeline
=======================
```
bash run.sh
bash run.coverage.sh
bash run.interaction.sh
```

Output files
============
```
*.DNA.fastq # the DNA reads
*.RNA.fastq # the RNA reads
*.DNA.bam # the DNA reads align result
*.RNA.bam # the RNA reads align result
*.bw # visualization in IGV 
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