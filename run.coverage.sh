PROGRAM_DIRECTORY='ChRDPETpipline/Tools'
OUTPUT_DIRECTORY='result/allrich-40'
OUTPUT_PREFIX='allrich-40'
BED_file="genome/genome.info"
EXT_LEN_up=2000
EXT_LEN_down=2000
GENE_LEN=2000
GENOME_LEN=360545087 # genome length


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

time=`date '+%s.%N'`
mkdir -p $OUTPUT_DIRECTORY/coverage
tmpdir=$OUTPUT_DIRECTORY/coverage
bamCoverage -o $tmpdir/$OUTPUT_PREFIX.DNA.bw --binSize 5 -b $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.bam --numberOfProcessors $NTHREADS --minMappingQuality $MAPPING_CUTOFF
bamCoverage -o $tmpdir/$OUTPUT_PREFIX.RNA.bw --binSize 5 -b $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.bam --numberOfProcessors $NTHREADS --minMappingQuality $MAPPING_CUTOFF
bamCoverage -o $tmpdir/$OUTPUT_PREFIX.DNA.1x.bw --binSize 5 -b $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.bam --numberOfProcessors $NTHREADS --minMappingQuality $MAPPING_CUTOFF --normalizeUsing RPGC --effectiveGenomeSize $GENOME_LEN
bamCoverage -o $tmpdir/$OUTPUT_PREFIX.RNA.1x.bw --binSize 5 -b $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.bam --numberOfProcessors $NTHREADS --minMappingQuality $MAPPING_CUTOFF --normalizeUsing RPGC --effectiveGenomeSize $GENOME_LEN
bamCoverage -o $tmpdir/$OUTPUT_PREFIX.DNA.RPKM.bw --binSize 5 -b $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.DNA.bam --numberOfProcessors $NTHREADS --minMappingQuality $MAPPING_CUTOFF --normalizeUsing RPKM
bamCoverage -o $tmpdir/$OUTPUT_PREFIX.RNA.RPKM.bw --binSize 5 -b $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.bam --numberOfProcessors $NTHREADS --minMappingQuality $MAPPING_CUTOFF --normalizeUsing RPKM

bamCoverage -o $tmpdir/$OUTPUT_PREFIX.RNA.fwd.bw -b $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.bam --samFlagExclude 16 --binSize 5 --numberOfProcessors $NTHREADS --minMappingQuality $MAPPING_CUTOFF
bamCoverage -o $tmpdir/$OUTPUT_PREFIX.RNA.rev.bw -b $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.bam --samFlagInclude 16 --binSize 5 --numberOfProcessors $NTHREADS --minMappingQuality $MAPPING_CUTOFF
bamCoverage -o $tmpdir/$OUTPUT_PREFIX.RNA.fwd.1x.bw -b $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.bam --samFlagExclude 16 --binSize 5 --numberOfProcessors $NTHREADS --minMappingQuality $MAPPING_CUTOFF --normalizeUsing RPGC --effectiveGenomeSize $GENOME_LEN
bamCoverage -o $tmpdir/$OUTPUT_PREFIX.RNA.rev.1x.bw -b $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.bam --samFlagInclude 16 --binSize 5 --numberOfProcessors $NTHREADS --minMappingQuality $MAPPING_CUTOFF --normalizeUsing RPGC --effectiveGenomeSize $GENOME_LEN
bamCoverage -o $tmpdir/$OUTPUT_PREFIX.RNA.fwd.RPKM.bw -b $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.bam --samFlagExclude 16 --binSize 5 --numberOfProcessors $NTHREADS --minMappingQuality $MAPPING_CUTOFF --normalizeUsing RPKM
bamCoverage -o $tmpdir/$OUTPUT_PREFIX.RNA.rev.RPKM.bw -b $OUTPUT_DIRECTORY/$OUTPUT_PREFIX.RNA.bam --samFlagInclude 16 --binSize 5 --numberOfProcessors $NTHREADS --minMappingQuality $MAPPING_CUTOFF --normalizeUsing RPKM

computeMatrix reference-point --referencePoint TSS -S $tmpdir/$OUTPUT_PREFIX.DNA.1x.bw --regionsFileName $BED_file -a $EXT_LEN_up -b $EXT_LEN_down --skipZeros --outFileName $tmpdir/$OUTPUT_PREFIX.DNA.TSS.gz --numberOfProcessors $NTHREADS; plotProfile -m $tmpdir/$OUTPUT_PREFIX.DNA.TSS.gz -out $tmpdir/$OUTPUT_PREFIX.DNA.TSS.pdf
computeMatrix scale-regions -S $tmpdir/$OUTPUT_PREFIX.RNA.1x.bw -R $BED_file -a $EXT_LEN_up -b $EXT_LEN_down -m $GENE_LEN --skipZeros --outFileName $tmpdir/$OUTPUT_PREFIX.RNA.gene.gz --numberOfProcessors $NTHREADS --skipZeros; plotProfile -m $tmpdir/$OUTPUT_PREFIX.RNA.gene.gz -out $tmpdir/$OUTPUT_PREFIX.RNA.gene.pdf
computeMatrix scale-regions -S $tmpdir/$OUTPUT_PREFIX.RNA.fwd.bw $tmpdir/$OUTPUT_PREFIX.RNA.rev.bw -R $BED_file -a $EXT_LEN_up -b $EXT_LEN_down -m $GENE_LEN --outFileName $tmpdir/$OUTPUT_PREFIX.RNA.sense.richheatmap.gz --outFileNameMatrix $tmpdir/$OUTPUT_PREFIX.RNA.sense.richheatmap.matrix --numberOfProcessors $NTHREADS --skipZeros; python $PROGRAM_DIRECTORY/sensecg.py $tmpdir/$OUTPUT_PREFIX.RNA.sense.richheatmap.gz | gzip > $tmpdir/$OUTPUT_PREFIX.RNA.sense.richheatmap.cg.gz; plotProfile -m $tmpdir/$OUTPUT_PREFIX.RNA.sense.richheatmap.cg.gz -out $tmpdir/$OUTPUT_PREFIX.RNA.sense.richheatmap.cg.pdf --perGroup

echo coverage finish : `date`
dur=`echo "$(date +%s.%N) - $time" | bc`

