import sys

def compare(mylist):
    if len(mylist) == 1:
        print("\t".join(mylist[0]))
    else:
        tmp = mylist[0]
        for line in mylist[1:]:
            if int(line[11]) > int(tmp[11]):
                tmp = line
        print("\t".join(tmp))

if len(sys.argv) == 2:
    fin = open(sys.argv[1],'r')
else:
    fin = sys.stdin

flag = None
out = []
for line in fin:
    tmp = line.strip().split("\t")
    ID = "\t".join(tmp[0:7])
    if flag != None and flag != ID:
        compare(out)
        out = []
    flag = ID
    out.append(tmp)
compare(out)
fin.close()