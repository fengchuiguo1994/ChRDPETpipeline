import time
import argparse

my_arp = argparse.ArgumentParser(description="combine DNA and RNA bed to contain bedpe file")
my_arp.add_argument('DNAFile',help="the input DNA bed file")
my_arp.add_argument('RNAFile',help="the input RNA bed file")
my_arp.add_argument('bedpeFile',help="the output contain bedpe file")
my_arp.add_argument('-q','--mapq',default=2,help='the min mapq',type=int)
arp = my_arp.parse_args()

with open(arp.DNAFile) as dna,open(arp.RNAFile) as rna,open(arp.bedpeFile,'w') as bedpe:
    my_dict = {}
    start = time.time()
    for line in dna:
        temp = line.strip().split()
        if int(temp[4]) >= arp.mapq:
            my_dict[temp[3]] = temp
    print("deal with DNA file use time : %ds" %(time.time()-start))
    
    start = time.time()
    for line in rna:
        temp = line.strip().split()
        if int(temp[4]) >= arp.mapq and temp[3] in my_dict:
            qq = temp[4] if int(temp[4]) < int(my_dict[temp[3]][4]) else my_dict[temp[3]][4]
            bedpe.write("\t".join([my_dict[temp[3]][0],my_dict[temp[3]][1],my_dict[temp[3]][2],temp[0],temp[1],temp[2],temp[3],qq,my_dict[temp[3]][5],temp[5],my_dict[temp[3]][6],temp[6],my_dict[temp[3]][10],temp[7],"\n"]))
    print("deal with RNA file and output the bedpe file use time : %ds" %(time.time()-start))