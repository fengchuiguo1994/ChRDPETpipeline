use strict;
use warnings;

my $file = $ARGV[0];
my $out = $ARGV[1];
open IN,"<$file";
open OUT1,">$out.DNA.short.fastq";
open OUT2,">$out.DNA.long.fastq";
my $cutoff = $ARGV[2];
while(<IN>){
	my $line = $_;
	my $line2 = <IN>;
	$line .= $line2;
	$line .= <IN>;
	$line .= <IN>;
	if(length($line2)-1 >= $cutoff){
		print OUT2 $line;
	}
	else{
		print OUT1 $line;
	}
}
