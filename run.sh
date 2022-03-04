PROGRAM_DIRECTORY='ChRDPETpipline/Tools'
OUTPUT_DIRECTORY='result/allrich-40'
OUTPUT_PREFIX='allrich-40'
BWA_GENOME_INDEX='genome/genome.fa'
HISAT_GENOME_INDEX='genome/genome'
BOWTIE2_GENOME_INDEX='genome/genome'
knownspl='genome/genome.ss'
Linker_file='linker/adapter.fa'
IN1='allrich-40_R1.fq.gz'
IN2='allrich-40_R2.fq.gz'


NTHREADS='20' ### number of threads used in mapping reads to a reference genome
function jobmax
{
    typeset -i MAXJOBS=$1
    sleep .2
    while (( ($(pgrep -P $$ | wc -l) - 1) >= $MAXJOBS ))
    do
        sleep .2
    done
}


###### split data to combine or independent,and find linker
start=`date '+%s.%N'`
time=`date '+%s.%N'`
echo flash start :  `date`
flash --threads $NTHREADS -M 145 -O --output-prefix $OUTPUT_PREFIX.flash --output-directory $OUTPUT_DIRECTORY $IN1 $IN2
echo flash finish : `date`
dur=`echo "$(date +%s.%N) - $time" | bc`
printf "Execution time for flash : %.6f seconds\n" $dur


time=`date '+%s.%N'`
echo cutadapt start : `date`
cutadapt -b file:$Linker_file -n 14 --no-indels -o $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.combine.noLinker --info-file $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.combine.Linker_info --discard -O 18 $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.flash.extendedFrags.fastq > $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.combine.stat &
cutadapt -b file:$Linker_file -n 8 --no-indels -o $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.notCombined.1.noLinker --info-file $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.notCombined.1.Linker_info --discard -O 18 $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.flash.notCombined_1.fastq > $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.notCombined.1.stat & 
cutadapt -b file:$Linker_file -n 8 --no-indels -o $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.notCombined.2.noLinker --info-file $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.notCombined.2.Linker_info --discard -O 18 $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.flash.notCombined_2.fastq > $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.notCombined.2.stat &
wait
echo cutadapt finish : `date`
echo transform start : `date`
perl $PROGRAM_DIRECTORY/ts_cutadapt2oneline.pl $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.combine.Linker_info $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.combine.cut.info > $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.combine.cut.info.log &
perl $PROGRAM_DIRECTORY/ts_cutadapt2oneline.pl $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.notCombined.1.Linker_info $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.notCombined.1.cut.info > $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.notCombined.1.cut.info.log &
perl $PROGRAM_DIRECTORY/ts_cutadapt2oneline.pl $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.notCombined.2.Linker_info $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.notCombined.2.cut.info > $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.notCombined.2.cut.info.log &
wait
echo transform finish : `date`
dur=`echo "$(date +%s.%N) - $time" | bc`
printf "Execution time for cutadapt and transform : %.6f seconds\n" $dur


###### according linker,split RNA and DNA
time=`date '+%s.%N'`
echo split DNA and RNA start : `date`
perl $PROGRAM_DIRECTORY/split.combine.pl  $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.combine.cut.info $OUTPUT_DIRECTORY/$OUTPUT_PREFIX 1> $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.combine.fq.stat 2>$OUTPUT_DIRECTORY/$OUTPUT_PREFIX.combine.fq.stat.log &
perl $PROGRAM_DIRECTORY/split.only.pl $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.notCombined.1.cut.info $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.notCombined.2.cut.info $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.only 1> $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.only.fq.stat 2>$OUTPUT_DIRECTORY/$OUTPUT_PREFIX.only.fq.stat.log & 
wait
cat $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.combine.RNA.fq $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.only.RNA.fq > $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.fastq &
cat $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.combine.DNA.fq $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.only.DNA.fq > $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.fastq &
wait
echo split DNA and RNA finish : `date`
dur=`echo "$(date +%s.%N) - $time" | bc`
printf "Execution time for split DNA and RNA : %.6f seconds\n" $dur


####### mapping reads to a reference genome,and make multi-align to only match,sam2bam
time=`date '+%s.%N'`
echo map DNA and RNA reads to genome start : `date`
perl $PROGRAM_DIRECTORY/split.pl $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.fastq $OUTPUT_DIRECTORY/$OUTPUT_PREFIX 70
bwa aln -t $NTHREADS -f $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.short.sai $BWA_GENOME_INDEX $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.short.fastq && bwa samse -f $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.short.sam $BWA_GENOME_INDEX $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.short.sai $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.short.fastq 
bwa mem -t $NTHREADS $BWA_GENOME_INDEX $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.long.fastq > $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.long.sam 
hisat2 --known-splicesite-infile $knownspl -p $NTHREADS -x $HISAT_GENOME_INDEX --rna-strandness F -U $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.fastq -S $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.sam && python $PROGRAM_DIRECTORY/flt_bam.py $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.sam $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA && samtools sort -@ $NTHREADS -o $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.hisat.bam $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.uniqmap.bam
samtools view -Sb -F 256 $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.multimap.bam | bamToFastq -i - -fq $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.tmp.multi.fq &
bamToFastq -i $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.unmap.bam -fq $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.tmp.unmap.fq &
wait
cat $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.tmp.multi.fq $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.tmp.unmap.fq > $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.remap.fq
bowtie2 -p $NTHREADS --local --very-sensitive-local -x $BOWTIE2_GENOME_INDEX -U $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.remap.fq -S $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.remap.sam && samtools view -Sb -q 2 $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.remap.sam | samtools sort -@ $NTHREADS -o $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.remap.bam -
samtools merge -f $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.bam $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.hisat.bam $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.remap.bam
samtools index $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.bam &

echo map DNA and RNA reads to genome finish : `date`
dur=`echo "$(date +%s.%N) - $time" | bc`
printf "Execution time for map DNA and RNA reads to genome : %.6f seconds\n" $dur

time=`date '+%s.%N'`
echo map get the unique mapped reads start : `date`
java -cp $PROGRAM_DIRECTORY/LGL.jar LGL.util.UniqueSam $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.long.sam $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.long.rmdup.sam
python $PROGRAM_DIRECTORY/combine_DNA_file.py $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.short.sam $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.long.rmdup.sam $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.sam 
samtools view -Sb $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.sam | samtools sort -@ $NTHREADS -o $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.bam -
samtools index $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.bam &
wait
echo map get the unique mapped reads finish : `date`
dur=`echo "$(date +%s.%N) - $time" | bc`
printf "Execution time for map get the unique mapped reads : %.6f seconds\n" $dur


dur=`echo "$(date +%s.%N) - $start" | bc`
printf "Execution time for running the pipline : %.6f seconds\n" $dur
