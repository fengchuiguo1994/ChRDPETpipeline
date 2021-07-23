PROGRAM_DIRECTORY='ChRDPETpipline/Tools'
OUTPUT_DIRECTORY='result/allrich-40'
OUTPUT_PREFIX='allrich-40'
gene_file='genome/genome.gtf'
exon_file='genome/genome.gtf'
BED_file="genome/genome.info"
DNA_ANCHOR='MH63_H3K4me3.anchor' # H3K4me3 peak

NTHREADS='20' ### number of threads used in mapping reads to a reference genome
MAPPING_CUTOFF='20' ### cutoff of mapping quality score for filtering out low-quality or multiply-mapped reads
function jobmax
{
    typeset -i MAXJOBS=$1
    sleep .2
    while (( ($(pgrep -P $$ | wc -l) - 1) >= $MAXJOBS ))
    do
        sleep .2
    done
}


start=`date '+%s.%N'`
time=`date '+%s.%N'`
mkdir -p $OUTPUT_DIRECTORY/interaction
tmpdir=$OUTPUT_DIRECTORY/interaction
bamToBed -cigar -i $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.bam | awk -v OFS="\t" '{if($6=="+"){print $1,$2,$2+500,$4,$5,$6,$7}else{start=$3-500;if(start<0){start=0;}print $1,start,$3,$4,$5,$6,$7}}' | intersectBed -a - -b $DNA_ANCHOR -wao | python $PROGRAM_DIRECTORY/uniq_DNA.py > $tmpdir/$OUTPUT_PREFIX.DNA.bed &
htseq-count -o $tmpdir/$OUTPUT_PREFIX.RNA.yes.gene.sam -f bam -r name -s yes -t gene -i gene_id -m intersection-nonempty $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.bam $gene_file > $tmpdir/$OUTPUT_PREFIX.RNA.yes.gene.count &
wait

samtools view -H $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.bam | cat - $tmpdir/$OUTPUT_PREFIX.RNA.yes.gene.sam > $tmpdir/$OUTPUT_PREFIX.RNA.yes.gene.cg.sam &
wait

htseq-count -o $tmpdir/$OUTPUT_PREFIX.RNA.yes.exon.sam -f sam -r name -s yes -t exon -i gene_id -m intersection-nonempty $tmpdir/$OUTPUT_PREFIX.RNA.yes.gene.cg.sam $exon_file > $tmpdir/$OUTPUT_PREFIX.RNA.yes.exon.count &
wait

samtools view -H $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.bam | cat - $tmpdir/$OUTPUT_PREFIX.RNA.yes.exon.sam | perl -lane 'if(/XF:Z/){$_=~s/XF:Z/GE:Z/;print $_}else{print $_}' > $tmpdir/$OUTPUT_PREFIX.RNA.yes.sam &
wait
python $PROGRAM_DIRECTORY/sam2bed2.py $tmpdir/$OUTPUT_PREFIX.RNA.yes.sam 1> $tmpdir/$OUTPUT_PREFIX.RNA.yes.bed 2>$tmpdir/$OUTPUT_PREFIX.RNA.yes.bed.log &
wait

python $PROGRAM_DIRECTORY/combineDNAandRNA_withanchor.py $tmpdir/$OUTPUT_PREFIX.DNA.bed $tmpdir/$OUTPUT_PREFIX.RNA.yes.bed $tmpdir/$OUTPUT_PREFIX.DNARNA.bedpe
awk -v qu=$MAPPING_CUTOFF '$8>=qu' $tmpdir/$OUTPUT_PREFIX.DNARNA.bedpe | sort --parallel=$NTHREADS -k14,14 -k13,13 -k1,1 -k2,2n -k3,3n -k4,4 -k5,5n -k6,6n -k8,8n -k9,9 -k10,10 -k11,11 -k12,12 > $tmpdir/$OUTPUT_PREFIX.DNARNA.sorted.bedpe
python $PROGRAM_DIRECTORY//uniqread.py $tmpdir/$OUTPUT_PREFIX.DNARNA.sorted.bedpe >  $tmpdir/$OUTPUT_PREFIX.DNARNA.uniq.bedpe
python $PROGRAM_DIRECTORY/PetClusterWithGivenAnchors.py $DNA_ANCHOR $BED_file $tmpdir/$OUTPUT_PREFIX.DNARNA.uniq.bedpe | sort --parallel=$NTHREADS -k1,1 -k4,4 -k2,2n -k5,5n -k3,3n -k6,6n > $tmpdir/$OUTPUT_PREFIX.DNARNA.givenanchor.cluster
awk '$9>1' $tmpdir/$OUTPUT_PREFIX.DNARNA.givenanchor.cluster > $tmpdir/$OUTPUT_PREFIX.DNARNA.givenanchor.gt1.cluster
tmp=`wc -l $tmpdir/$OUTPUT_PREFIX.DNARNA.uniq.bedpe | awk '{print $1}'`
Rscript $PROGRAM_DIRECTORY/hypergeometric5.r $tmp $tmpdir/$OUTPUT_PREFIX.DNARNA.givenanchor.gt1.cluster $tmpdir/$OUTPUT_PREFIX.DNARNA.givenanchor.gt1.cluster.withpvalue
awk '$13+0.0<=0.05' $tmpdir/$OUTPUT_PREFIX.DNARNA.givenanchor.gt1.cluster.withpvalue > $tmpdir/$OUTPUT_PREFIX.DNARNA.givenanchor.FDRfiltered.txt
awk '$9>2' $tmpdir/$OUTPUT_PREFIX.DNARNA.givenanchor.FDRfiltered.txt > $tmpdir/$OUTPUT_PREFIX.DNARNA.givenanchor.FDRfiltered.gt2.txt
cat $tmpdir/$OUTPUT_PREFIX.DNARNA.givenanchor.FDRfiltered.gt2.txt | awk '{if($1==$4 && ($5+$6)>=($2+$3)) print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$9"\t"$12"\t"$13}' > $tmpdir/$OUTPUT_PREFIX.givenanchor.cluster.intra.DNA-RNA.curve
cat $tmpdir/$OUTPUT_PREFIX.DNARNA.givenanchor.FDRfiltered.gt2.txt |awk '{if($1==$4 && ($5+$6)<($2+$3)) print $4"\t"$5"\t"$6"\t"$1"\t"$2"\t"$3"\t"$9"\t"$12"\t"$13}' > $tmpdir/$OUTPUT_PREFIX.givenanchor.cluster.intra.RNA-DNA.curve

printf "Execution time for flash : %.6f seconds\n" $dur
dur=`echo "$(date +%s.%N) - $start" | bc`
printf "Execution time for running the pipline : %.6f seconds\n" $dur
