# ChRDPETpipline
Process ChRD-PET data

REQUIREMENTS
============
java8
python
perl
R

samtools
bowtie2
hisat2
bwa
[flash](http://ccb.jhu.edu/software/FLASH/)
cutadapt
bedtools
deeptools
HTSeq

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

Usage of ChRDPETpipline
```
bash run.sh
bash run.coverage.sh
```


My tools version
============
java8(1.8.0_161)
python(3.7.9)
perl(v5.26.2)
R(3.5.2)

samtools(1.9)
bowtie2(2.3.5.1)
hisat2(2.1.0)
bwa(0.7.15-r1140)
flash(v1.2.11)
cutadapt(2.3)
bedtools(v2.27.1)
deeptools(3.2.1)
HTSeq(0.11.2)