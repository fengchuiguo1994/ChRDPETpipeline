import pysam
import sys
import re
import operator

def main(samfin):
    if re.match("bam",samfin):
        samfile=pysam.AlignmentFile(samfin,'rb')
    else:
        samfile=pysam.AlignmentFile(samfin,'r')

    for line in samfile:
        if line.is_reverse:
            strand = "-"
        else:
            strand = "+"
        if line.get_tag("GE") == "__no_feature":
            print("\t".join([line.reference_name,str(line.reference_start),str(line.reference_end),line.query_name,str(line.mapping_quality),strand,line.cigarstring,"__no_feature"]))

        elif not re.match("__ambiguous",line.get_tag("GE")):
            if re.match("__no_feature",line.get_tag("XF")):
                out = line.get_tag("GE")+"-intron"
                print("\t".join([line.reference_name,str(line.reference_start),str(line.reference_end),line.query_name,str(line.mapping_quality),strand,line.cigarstring,out]))
            else:
                out = line.get_tag("GE")+"-exon"
                print("\t".join([line.reference_name,str(line.reference_start),str(line.reference_end),line.query_name,str(line.mapping_quality),strand,line.cigarstring,out]))

        else:
            out = []
            genelist = re.search("\[(.+?)\]",line.get_tag("GE"))[1].split("+")
            if re.match("__ambiguous",line.get_tag("XF")):
                exonlist = re.search("\[(.+?)\]",line.get_tag("XF"))[1].split("+")
            elif re.match("__no_feature",line.get_tag("XF")):
                exonlist = []
            else:
                exonlist = []
                exonlist.append(line.get_tag("XF"))
            for i in genelist:
                if i in exonlist:
                    out.append(i+"-exon")
                else:
                    out.append(i+"-intron")
            outtext = ";".join(out)
            print("\t".join([line.reference_name,str(line.reference_start),str(line.reference_end),line.query_name,str(line.mapping_quality),strand,line.cigarstring,outtext]))

if __name__ == "__main__":
    main(sys.argv[1])
