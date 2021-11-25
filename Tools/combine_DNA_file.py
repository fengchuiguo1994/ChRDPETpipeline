import pysam
import sys

with pysam.AlignmentFile(sys.argv[1],'r') as shortfl,pysam.AlignmentFile(sys.argv[2],'r') as longfl:
    header = longfl.header.to_dict()
    header['PG'].append(shortfl.header['PG'][0])
    with pysam.AlignmentFile(sys.argv[3],'w',header=header) as outfl:
        for line in shortfl:
            if line.has_tag('XT') and line.get_tag('XT')=="U":
                outfl.write(line)
        for line in longfl:
            if line.has_tag('AS') and line.has_tag('XS') and line.get_tag('AS') != line.get_tag('XS'):
                outfl.write(line)

