import sys
import gzip
import json

myset = set()
if len(sys.argv) > 2:
    myset = set(sys.argv[2:])
with gzip.open(sys.argv[1],'rt') as fin:
    head=None
    mydict = {}
    count = 0
    out = []
    bins = None
    qian = None
    hou = None
    for i,line in enumerate(fin):
        if i==0:
            head = line
            tmp = head[1:]
            mydict = json.loads(tmp)
            bins = mydict["bin size"][0]
            qian = mydict["sample_boundaries"][1]
            hou = mydict["sample_boundaries"][2]
        else:
            mytmp = line.strip().split("\t")
            if mytmp[3] in myset:
                continue
            flag = 0
            for j in mytmp[6:]:
                if float(j) > 0:
                    flag = 1
                    break
            if flag == 0:
                continue
            count += 1
            if mytmp[5] == "+":
                out.append(line.strip())
            else:
                out.append("\t".join(mytmp[0:6]+mytmp[6+qian:]+mytmp[6:6+qian]))
    mydict["group_boundaries"][1] = count
    mydict["sample_labels"][0] = mydict["sample_labels"][0].replace('fwd','sense')
    mydict["sample_labels"][1] = mydict["sample_labels"][1].replace('rev','anti-sense')
    head = json.dumps(mydict)
    head = "@"+head
    print(head)
    print("\n".join(out))
sys.stdout.close()
