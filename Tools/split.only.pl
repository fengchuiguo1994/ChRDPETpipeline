use strict;
use warnings;
use Data::Dumper;

my ($in1,$in2,$out) = @ARGV;
#perl split.only.pl data.1.only.tr.txt data.2.only.tr.txt data.only > only.stat
open IN1,"<$in1";
open IN2,"<$in2";
open RNA,">$out.RNA.fq";
open DNA,">$out.DNA.fq";
open CONTAINDNA,">$out.contain.DNA.fq";
open CONTAINRNA,">$out.contain.RNA.fq";
open LOG,">$out.maybe_true.seq";
my %hash;

while(<IN1>)#out.14.tr.txt
{
	chomp;
	my $read1 = $_;
	my @tmp1 = split/\t/,$_;
	my $tmp = <IN2>;
	chomp($tmp);
	my @tmp2 = split/\t/,$tmp;
	my $read2 = $tmp;

	$hash{"$tmp1[1]_$tmp2[1]"} += 1;
	my $sum = $tmp1[1]+$tmp2[1];
	$hash{$sum} += 1;
	if($tmp1[1] == 1 && $tmp2[1] == 0)
	{
		if(scalar(@tmp1) == 4 && scalar(@tmp2) == 4) # R1 just have linker,R2 just have seq ** ----
		{
			print LOG "it come cross question3\n";
			print LOG "@tmp1\n";
			print LOG "@tmp2\n";
		}
		elsif(length($tmp1[2]) < 18 || length($tmp1[4])<18) # too short
		{
			$hash{'1_0_0_0'} += 1;
		}
		elsif($tmp1[3] =~ /^\w+#(A_?)$/) #------ -- ------ only data1
		{
			if($1 eq 'A')#RNA kmer DNA
			{
				$tmp1[4] = rc($tmp1[4]);
				$tmp1[7] = reverse $tmp1[7];

				print RNA "\@$tmp1[0] 1\n";
				print RNA "$tmp1[2]\n";
				print RNA "+\n";
				print RNA "$tmp1[5]\n";
				print DNA "\@$tmp1[0] 2\n";
				print DNA "$tmp1[4]\n";
				print DNA "+\n";
				print DNA "$tmp1[7]\n";
				print CONTAINDNA "\@$tmp2[0]\n$tmp2[2]\n+\n$tmp2[3]\n"
			}
			elsif($1 eq 'A_')#DNA kmer RNA
			{
				$tmp1[4] = rc($tmp1[4]);
				$tmp1[7] = reverse $tmp1[7];

				print RNA "\@$tmp1[0] 1\n";
				print RNA "$tmp1[4]\n";
				print RNA "+\n";
				print RNA "$tmp1[7]\n";
				print DNA "\@$tmp1[0] 2\n";
				print DNA "$tmp1[2]\n";
				print DNA "+\n";
				print DNA "$tmp1[5]\n";
				print CONTAINRNA "\@$tmp2[0]\n$tmp2[2]\n+\n$tmp2[3]\n"
			}
			else
			{
				print "@tmp1\n";
				print "@tmp2\n";
			}
			$hash{'1_1_0_0'} += 1;
		}
		else
		{
			print LOG "it come cross question2\n";
			print LOG "@tmp1\n";
			print LOG "@tmp2\n";
		}
	}
	elsif($tmp1[1] == 0 && $tmp2[1] == 1)
	{
		if(scalar(@tmp1) == 4 && scalar(@tmp2) == 4) # R1 just have seq,R2 just have linker ---- **
		{
			print LOG "it come cross question1\n";
			print LOG "@tmp1\n";
			print LOG "@tmp2\n";
		}
		elsif(length($tmp2[2]) < 18 || length($tmp2[4]) < 18) # too short
		{
			$hash{'0_0_1_0'} += 1;
		}
		elsif($tmp2[3] =~ /^\w+#(A_?)$/)
		{
			if($1 eq 'A')#RNA kmer DNA
			{
				$tmp2[4] = rc($tmp2[4]);
				$tmp2[7] = reverse $tmp2[7];

				print RNA "\@$tmp2[0] 1\n";
				print RNA "$tmp2[2]\n";
				print RNA "+\n";
				print RNA "$tmp2[5]\n";
				print DNA "\@$tmp2[0] 2\n";
				print DNA "$tmp2[4]\n";
				print DNA "+\n";
				print DNA "$tmp2[7]\n";
				print CONTAINDNA "\@$tmp1[0]\n$tmp1[2]\n+\n+$tmp1[3]\n"
			}
			elsif($1 eq 'A_')#DNA kmer RNA
			{
				$tmp2[4] = rc($tmp2[4]);
				$tmp2[7] = reverse $tmp2[7];

				print RNA "\@$tmp2[0] 1\n";
				print RNA "$tmp2[4]\n";
				print RNA "+\n";
				print RNA "$tmp2[7]\n";
				print DNA "\@$tmp2[0] 2\n";
				print DNA "$tmp2[2]\n";
				print DNA "+\n";
				print DNA "$tmp2[5]\n";
				print CONTAINRNA "\@$tmp1[0]\n$tmp1[2]\n+\n+$tmp1[3]\n"
			}
			else
			{
				print "@tmp1\n";
				print "@tmp2\n";
			}
			$hash{'0_0_1_1'} += 1;
		}
		else
		{
			print LOG "it come cross question5\n";
			print LOG "@tmp1\n";
			print LOG "@tmp2\n";
		}
	}
	elsif($tmp1[1] == 1 && $tmp2[1] == 1)
	{
		my $ll1 = $1 if($tmp1[3] =~ /^\w+#(A_?)$/);
		my $ll2 = $1 if($tmp2[3] =~ /^\w+#(A_?)$/);
		if (!defined $ll1 || !defined $ll2) # one just have 
		{

		}
		elsif ($ll1 eq 'A' && $ll2 eq 'A')      ## drop
		{
			$hash{'1-A-1-A'} += 1;
		}
		elsif ($ll1 eq 'A' && $ll2 eq 'A_')
		{
			compare(\@tmp1,\@tmp2);
			$hash{'1-A-1-A_'} += 1;
		}
		elsif ($ll1 eq 'A_' && $ll2 eq 'A')
		{
			compare(\@tmp2,\@tmp1);
			$hash{'1-A_-1-A'} += 1;
		}
		elsif ($ll1 eq 'A_' && $ll2 eq 'A_')  ## drop
		{
			$hash{'1-A_-1-A_'} += 1;
		}
		else # it have only linker,no DNA/RNA sequencing
		{
			print LOG "it come cross question6\n";
			print LOG "@tmp1\n";
			print LOG "@tmp2\n";
		}
	}
}

print "$_\t$hash{$_}\n" foreach(sort{$a cmp $b} keys %hash);

sub rc{
	my $seq = $_[0];
	$seq =~ tr/ATCG/TAGC/;
	$seq = reverse($seq);
	return $seq;
}

sub compare{
	my $dd1 = shift;
	my $dd2 = shift;
	my @tmp1 = @{$dd1};
	my @tmp2 = @{$dd2};
	my ($flag1,$flag2) = (0,0);
	#E00512:349:HVKV7CCXY:4:1101:10703:2592  1       GGCTCGTAGATACAAACTAATTACTCAGGAAAAGAAAAAAAATATAACTAATCACGCTAATCTTCACTAAATATAGTGCTAATCACGTACATATTTTGGTTTCCGGTTTAGATGGCACTG        AGTCAGCTCAAGTATCGAGG#A_ CTGTCTCTTA      AAFFA-<AFJJJJJJFJJJAFJJJJJJJJJJJJJJJJFJJJJJAJJJJJJJFAJJJAJJAFJJJJJJJJJJJJJJJJA7AJJJFJJJJJJJJJJJ-FJFJ<FF7AJJJJJJFJFFJJJJJ        7F7FJJJFAFJJJJJJFFJJ    JJJJJFJJAF      
	#E00512:349:HVKV7CCXY:4:1101:10703:2592  1       #       CCTCGATACTTGAGCTGACT#A  CAGTGCCATCTAAACCGGAAACCAAAATATGTACGTGATTAGCACTATATTTAGTGAAGATTAGCGTGATTAGTTATATTTGTTTTCTTTTCCTGAGTAATTAGTTTGTATCTACGAGCCCTGTCTCTTA      #       AA<<FJJJJJJJFJJJJJJA    7JJFFJJJFFFJJJJJJJJJJF<AFJAFA<<JFJ-<-FFFJJJJJJJFJJJJJJFFJAFF-7F-AJ7<<JJJJJJJ<-FJJ7FJJF7A<-7A-FAFJJFJFFJFAJA-FJAFF<JJJAJF)AJF77FJAF

	#E00512:349:HVKV7CCXY:4:1101:12246:2592  1       GCACCGCA        CCTCGATACTTGAGCTGACT#A  AAAAAAAAAAAAACTTATTTAGGAACATGTATTTGTTGGATGATGAGGTTACTAGATTTTTTACATAGTTAAAATTAACTAACCTTCTTGTTTTGCTTAGTGCTATTCTTCTGTCTCTTATA      AAAFFJJ<        FAJ--<FJF7JFJJJJFJJJ    <J-FJJ-<<FJJJ<F-7AF-7<F-<<FA<-A-77-A7--7-7----7---<7---7<------<7----7----7F7----7-7-777F--A7--7----F--7-----A----------7-
	#E00512:349:HVKV7CCXY:4:1101:12246:2592  1       AAGTATAGCACTAAGCTAATCAAGTCGGTTAGTTAATTTTAGCCATGTATAAAATCTAGTTAGCTCCTACTCCTACTACTACATTTTCCTTAATTAGTTTTTTTTTTTTT  AGTCAGCTCAAGTATCGATG#A_ TTCGGTGCCTGTTTCTTATA    AAAFF<JJJJJJJJFJJJJFFJJF-F7-7<<7JJJ-FJJJJJJJJJJJJJJAJFJJFJFFJJF<7F7--<FFAJF<AJFFJ<-A--FF<-FJAFJ-<JFJFJJJJFJJJJ  -<77--A-F7<-77---77-    7--77-7-7--7----7AF-    
	if(length($tmp1[2]) >= 10 && length($tmp2[4]) >= 10)# --  ---- and ---- -- ----
	{
		my $tmplen = length($tmp1[2]);
		$tmplen = length($tmp2[4]) if(length($tmp2[4]) < length($tmp1[2]));
		my $tmp = substr($tmp1[2],length($tmp1[2])-$tmplen,$tmplen);
		$tmp = rc($tmp);
		my $se = substr($tmp2[4],0,$tmplen);
		$flag1 = compseq($tmp,$se);
	}
	if(length($tmp1[4]) >= 10 && length($tmp2[2]) >= 10){
		my $tmplen = length($tmp1[4]);
		$tmplen = length($tmp2[2]) if(length($tmp2[2]) < length($tmp1[4]));
		my $tmp = substr($tmp2[2],length($tmp2[2])-$tmplen,$tmplen);
		$tmp = rc($tmp);
		my $se = substr($tmp1[4],0,$tmplen);
		$flag2 = compseq($tmp,$se);
	}

	my $rna1 = "\@$tmp1[0] 1\n";
	my $rna2 = "$tmp1[2]\n";
	my $rna3 = "+\n";
	my $rna4 = "$tmp1[5]\n";

	if(length($tmp1[2]) < length($tmp2[4])){
		$tmp2[4] = rc($tmp2[4]);
		$tmp2[7] = reverse $tmp2[7];
		$rna1 = "\@$tmp2[0] 1\n";
		$rna2 = "$tmp2[4]\n";
		$rna3 = "+\n";
		$rna4 = "$tmp2[7]\n";
	}

	$tmp1[4] = rc($tmp1[4]);
	$tmp1[7] = reverse $tmp1[7];
	my $dna1 =  "\@$tmp1[0] 2\n";
	my $dna2 =  "$tmp1[4]\n";
	my $dna3 =  "+\n";
	my $dna4 =  "$tmp1[7]\n";
	if(length($tmp2[2]) > length($tmp1[4])){
		$dna1 =  "\@$tmp2[0] 2\n";
		$dna2 =  "$tmp2[2]\n";
		$dna3 =  "+\n";
		$dna4 =  "$tmp2[5]\n";
	}

	if(($flag1 == 1 || $flag2 == 1) && ($flag1 != -1 && $flag2 != -1)){
		print STDERR "$flag1\t$flag2\n";
		if (length($dna2) > 18 && length($rna2) > 18)
		{
			print DNA "$dna1$dna2$dna3$dna4";
			print RNA "$rna1$rna2$rna3$rna4";
		}
	}
	else{
		print STDERR "$flag1\t$flag2\n";
#		print "@tmp1\n@tmp2\n";
	}
}

sub compseq{
	my $a = shift;
	my $b = shift;
	my @a = split("",$a);
	my @b = split("",$b);
	my $sum = 0;
	foreach(0..$#a){
		$sum += 1 if($a[$_] eq $b[$_]);
	}
	if($sum/length($a)>=0.8){
		return 1;
	}else{
		return -1;
	}
}

=cut
E00492:486:H57TFCCX2:1:1101:29995:13685
R1:   GATTCAACCTGCCAGTCAGCTCAAGTATCGAGGGCGCGCGAGGGCTCCCTCGATACTTGAGCTGACTGGCAGGTTGAATCCGTCGTTTAAAACCGATAAGCAGGCTTTGCGTGGAAAACTAAAACGAAGTTGAGGGGTCAATTGACTTCC
      AAAFFJFJJJJJAF<FJJJJJ7FJJJF-JF<<A-----777JJJAJJJFJJ7<<FAFFJJJ-AA<-FJ<JJAA-7A<<F<JJ<AJ7A---7JA<J-FAFJ<A7-A<F-AJJJJF-AAF<AJAJJAA--7--7------7)----7<F7-<
R1flt:              GTCAGCTCAAGTATCGAGG
R1linker:           GTCAGCTCAAGTATCGAGG#A_
                                    CTGTCTCTTATA
                                    TATAAGAGACAG
-:45
quali = 45-33 = 12
R2:   GTCAGGGAGTGTGCGCCATTTGGAAGTCAATTGATCTCTTCACTTCGTTTTAGTTTTCCACGCAAAGCATGCGTATCGGTTTTAAACGACGGATTCAACCTGCCAGTGAGCTCAAGTATCGAGGGAGGCCTCGGGCGCCCTCGATAGTTG
R2flt:              GCCATTTGGAAGTCAATTGATCTCTTCACTTCGTTTTAGTTTTCCACGCAAAGCATGCGTATCGGTTTTAAACGACGGATTCAACCTGCCAGTGAGCTCAAGTATCGAGGG
R2linker:

E00492:486:H57TFCCX2:1:1101:30218:24726
GAGTACACCATCCAAGTCAGCTCAAGTATCGAGGTGACGTTCAGAGCGCTGGGCAGTAATCACATTGTGTCAGCATCCGCGCGTACCATCGCATTGCTTTGTTTTAATTAAACAGTCGGATTCCCCTTGTCCGTACCAGTTCTGAGTCTC
A--<AF7-A-FF<AAAFA-FJA-<--7<FFF-<F-----<7<<<FJJ--A--77-77----<AAF<---<7FF<7<---AF---7-77J7--7-F-AJFAJ-AJJ--7--7AJ<--777-A-77FJ-A-FJ-FJF7)<A-7-AA-77<7-
              AGTCAGCTCAAGTATCGAGG
              AGTGAGCTCAAGTATCGAGG#A_
=pod