import sys

anchordict={}
genedict={}
with open(sys.argv[1],'r') as anchor,open(sys.argv[2],'r') as geneinfo:
	for line in anchor:
		tmp = line.strip().split("\t")
		anchordict[tmp[3]] = tmp
	for line in geneinfo:
		tmp = line.strip().split("\t")
		genedict[tmp[6]] = tmp

outdict = {}
anchor1 = {}
anchor2 = {}
with open(sys.argv[3],'r') as fin:
	for line in fin:
		tmp = line.strip().split("\t")
		if tmp[12].startswith('anchor'):
			for kk in tmp[12].split(";"):
				if kk not in anchor1:
					anchor1[kk] = 0
				anchor1[kk] += 1
		if not tmp[13].startswith("_"):
			for kk in tmp[13].split(";"):
				ll = kk.split("-")[0]
				if ll not in anchor2:
					anchor2[ll] = 0
				anchor2[ll] += 1
		if tmp[12].startswith('anchor') and not tmp[13].startswith("_"):
			for nn in tmp[12].split(";"):
				for mm in tmp[13].split(";"):
					ww = mm.split("-")[0]
					ID = nn+"\t"+ww
					if ID not in outdict:
						outdict[ID] = 0
					outdict[ID] += 1

for i in outdict:
	tmp = i.split("\t")
	print("\t".join(anchordict[tmp[0]][0:3])+"\t"+"\t".join(genedict[tmp[1]][0:3])+"\t"+i+"\t"+str(outdict[i])+"\t"+str(anchor1[tmp[0]])+"\t"+str(anchor2[tmp[1]]))