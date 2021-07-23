import sys

def main(filein):
    with open(filein) as fin:
        flag = None
        out = None
        for line in fin:
            tmp = line.strip().split()
            xulie = "\t".join(tmp[0:6]+tmp[7:])
            if flag != None and xulie != flag:
                print(out)
            flag = xulie
            out = line.strip()
        print(out)

if __name__ == "__main__":
    main(sys.argv[1])
