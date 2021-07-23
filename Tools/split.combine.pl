use strict;
use warnings;

my ($in,$out) = @ARGV;
#perl split.combine.pl  out.14.tr.txt data > combine.stat
open IN,"<$in";
open RNA,">$out.combine.RNA.fq";
open DNA,">$out.combine.DNA.fq";
my %hash;

while(<IN>)#out.14.tr.txt
{
	chomp;
	my @tmp = split/\t/,$_;
	$hash{$tmp[1]} += 1;
	if($tmp[1] == 1) #---- ** ----(have two)
	{
		if(scalar(@tmp) == 4) # ---- ** or ** ----(just have DNA or RNA data,remove it)
		{
			print STDERR "remove just have DNA/RNA data,even no reads\n";
			print STDERR "$_\n";
		}
		elsif(length($tmp[2]) >= 18 && length($tmp[4]) >= 18)
		{
			if($tmp[3] =~ /^\w+#(A_?)$/)
			{
				if($1 eq 'A')#RNA kmer DNA
				# {
				# 	print RNA "\@$tmp[0] 1\n";
				# 	print RNA "$tmp[2]\n";
				# 	print RNA "+\n";
				# 	print RNA "$tmp[5]\n";
				# 	print DNA "\@$tmp[0] 2\n";
				# 	print DNA "$tmp[4]\n";
				# 	print DNA "+\n";
				# 	print DNA "$tmp[7]\n";
				# }
				{
					$tmp[4] = reverse $tmp[4];
					$tmp[4] =~ tr/ATCG/TAGC/;
					$tmp[7] = reverse $tmp[7];
					print RNA "\@$tmp[0] 1\n";
					print RNA "$tmp[2]\n";
					print RNA "+\n";
					print RNA "$tmp[5]\n";
					print DNA "\@$tmp[0] 2\n";
					print DNA "$tmp[4]\n";
					print DNA "+\n";
					print DNA "$tmp[7]\n";
				}
				elsif($1 eq 'A_')#DNA kmer RNA
				{
					$tmp[4] = reverse $tmp[4];
					$tmp[4] =~ tr/ATCG/TAGC/;
					$tmp[7] = reverse $tmp[7];
					print RNA "\@$tmp[0] 1\n";
					print RNA "$tmp[4]\n";
					print RNA "+\n";
					print RNA "$tmp[7]\n";
					print DNA "\@$tmp[0] 2\n";
					print DNA "$tmp[2]\n";
					print DNA "+\n";
					print DNA "$tmp[5]\n";
				}
				else
				{
					print "it seem have a trouble,please check:$1\n";
				}
			}
			$hash{'1_1'} += 1;
		}
		else
		{
			$hash{'1_2'} += 1;
		}
	}
}

print "$_\t$hash{$_}\n" foreach(sort{$a cmp $b} keys %hash);