import pysam
import sys

'''
python flt_bam.py allrich-06.RNA.sam allrich-06
python flt_bam.py input.bam/sam output_prefix
'''

if sys.argv[1].endswith(".bam"):
    mysam = pysam.AlignmentFile(sys.argv[1],'rb')
else:
    mysam = pysam.AlignmentFile(sys.argv[1],'r')

prefix = sys.argv[2]
unmap = prefix+".unmap.bam"
uniqmap = prefix+".uniqmap.bam"
multimap = prefix+".multimap.bam"
un = pysam.AlignmentFile(unmap,'wb',header=mysam.header)
uniq = pysam.AlignmentFile(uniqmap,'wb',header=mysam.header)
multi = pysam.AlignmentFile(multimap,'wb',header=mysam.header)

for line in mysam:
    if line.is_unmapped:
        un.write(line)
    else:
        if line.get_tag('NH') == 1:
            uniq.write(line)
        else:
            multi.write(line)
un.close()
uniq.close()
multi.close()