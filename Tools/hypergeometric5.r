#N <- as.matrix(read.table("nTags.txt"))
###### input format for data
###### AB  A  B
###### AB: pet count between anchors A and B
###### A: tags in anchor A
###### B: tags in anchor B
Args <- commandArgs()
if (length(Args) != 8)
{
	stop("the commans is like:Rscript hypergeometric.r count inputfile outputfile\n")
	
}
N <- as.numeric(Args[6])
#data <- as.matrix(read.table("data.txt"))
data <- read.table(Args[7],header=F)
nRows <- length(data[,1])
#q <- data[,9] - 1
#m <- data[,10]
#n <- N - m
#k <- data[,11]
#x <- phyper(q, m, n, k, lower.tail = FALSE)
data[,12] <- phyper(data[,9]-1, data[,10], N-data[,10], data[,11], lower.tail = FALSE)

###### p-value adjustment with Benjamini-Hockberg method
#fdr <- p.adjust(x, "BH")
data[,13] <- p.adjust(data[,12], "BH")
data[,14:15] <- -log10(data[,12:13]) ###### -log10(p-value)
data[is.infinite(data[,14]),14] <- 1000 ###### replace the extreme values with 1000
data[is.infinite(data[,14]),14] <- 1000 ###### replace the extreme values with 1000
for (i in 12:13) {
  data[[i]] <- as.numeric(format(data[[i]], digits = 3))
}
for (i in 14:15) {
  data[[i]] <- round(data[[i]], 2)
}
write.table(data, file=Args[8], sep = "\t", row.names = FALSE, col.names = FALSE,quote=F)
