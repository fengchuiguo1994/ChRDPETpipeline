use strict;
use warnings;

my ($in,$out) = @ARGV;

open IN,"<$in";
open OUT,">$out";

my $flag;
my @flag;
my %static;
while(<IN>)
{
	chomp;
	my $line = $_;
	$line =~ s/\t+/\t/g;
	$line =~ s/\t$//g;
	if(!defined $flag)
	{
		$flag = (split/\s+/,$line)[0];
		push@flag,$line;
	}
	else
	{
		my $tmp = (split/\s+/,$line)[0];
		if($tmp eq $flag)
		{
			push@flag,$line;
		}
		else
		{
			my ($linkercount,$linkerstat) = &fun(@flag);
			if($linkerstat eq 'yes')
			{
				$static{$linkercount} += 1;
			}
			else
			{
				$static{'nolinker'} += 1;
			}
			$flag = $tmp;
			undef @flag;
			push @flag,$line;
		}
	}
}

my ($linkercount,$linkerstat) = &fun(@flag);
if($linkerstat eq 'yes')
{
	$static{$linkercount} += 1;
}
else
{
	$static{'nolinker'} += 1;
}
print "$_\t$static{$_}\n" foreach(sort{$a cmp $b} keys %static);
close IN;
close OUT;


sub fun
{
	my @data = @_;
	my $num = scalar @data;
	my (@out,@qvalue);
	if($num == 1)
	{
		my @tmp = split /\t/,$data[0];
		my $tt = (split /\s+/,$tmp[0])[0];
		if(scalar @tmp == 4)
		{
			print OUT "$tt\t0\t$tmp[2]\t$tmp[3]\n";
			return (1,'no');
		}
		elsif(scalar @tmp == 11)#---- -- ----model
		{
			print OUT "$tt\t1\t$tmp[4]\t$tmp[5]#$tmp[7]\t$tmp[6]\t$tmp[8]\t$tmp[9]\t$tmp[10]\n";
		}
		elsif(scalar @tmp == 9 && $tmp[2] == 0)#-- ----model
		{
			print OUT "$tt\t1\t#\t$tmp[4]#$tmp[6]\t$tmp[5]\t#\t$tmp[7]\t$tmp[8]\n";
		}
		elsif(scalar @tmp == 9 && $tmp[2] > 0)#---- --model
		{
			print OUT "$tt\t1\t$tmp[4]\t$tmp[5]#$tmp[6]\t#\t$tmp[7]\t$tmp[8]\t#\n";
		}
		elsif(scalar @tmp == 7)# -- model  only linker
		{
			print OUT "$tt\t1\t$tmp[4]#$tmp[5]\t$tmp[6]\n";
		}
		elsif(scalar @tmp == 2) # no reads
		{
			print OUT "$tt\t0\t#\t#\n";
		}
		else
		{
			print "it maybe have wenti1\n";
			print "$_\t$tmp[$_]\n" foreach(0..$#tmp);
		}
		return (1,'yes');
	}
	elsif($num > 1)
	{
		foreach my $i (0..$num-1) {
			my @tmp = split /\t/,$data[$i];
			if($i == 0)
			{
				if(scalar @tmp == 11)#---- -- ----model
				{
					$tmp[5] .= "#$tmp[7]";
					push @out,@tmp[4,5,6];
					push @qvalue,@tmp[8,9,10];
				}
				elsif(scalar @tmp == 9 && $tmp[2] == 0)#-- ----model
				{
					$tmp[4] .= "#$tmp[6]";
					push @out,@tmp[4,5];
					push @qvalue,@tmp[7,8];
				}
				elsif(scalar @tmp == 9 && $tmp[2] > 0)#---- --model
				{
					$tmp[5] .= "#$tmp[6]";
					push @out,@tmp[4,5];
					push @qvalue,@tmp[7,8];
				}
				elsif(scalar @tmp == 7)# -- model  only linker
				{
					$tmp[4] .= "#$tmp[5]";
					push @out,$tmp[4];
					push @qvalue,$tmp[6];
				}
				else
				{
					print "it maybe have wenti2,check it\n";
				}
			}
			else
			{
				if(scalar @tmp == 11)#---- -- ----model
				{
					my $str = join('',@tmp[4,5,6]);
					$tmp[5] .= "#$tmp[7]";
					foreach my $j (0..$#out) {
						if($out[$j] eq $str)
						{
							my @temp = @out[$j+1..$#out];
							@out = @out[0..$j-1];
							push @out,@tmp[4,5,6];
							push @out,@temp;
							@temp = @qvalue[$j+1..$#qvalue];
							@qvalue = @qvalue[0..$j-1];
							push @qvalue,@tmp[8,9,10];
							push @qvalue,@temp;
							last;
						}
					}
				}
				elsif(scalar @tmp == 9 && $tmp[2] == 0)#-- ----model
				{
					my $str = join('',@tmp[4,5]);
					$tmp[4] .= "#$tmp[6]";
					foreach my $j (0..$#out) {
						if($out[$j] eq $str)
						{
							my @temp = @out[$j+1..$#out];
							@out = @out[0..$j-1];
							push @out,@tmp[4,5];
							push @out,@temp;
							@temp = @qvalue[$j+1..$#qvalue];
							@qvalue = @qvalue[0..$j-1];
							push @qvalue,@tmp[7,8];
							push @qvalue,@temp;
							last;
						}
					}
				}
				elsif(scalar @tmp == 9 && $tmp[2] > 0)#---- --model
				{
					my $str = join('',@tmp[4,5]);
					$tmp[5] .= "#$tmp[6]";
					foreach my $j (0..$#out) {
						if($out[$j] eq $str)
						{
							my @temp = @out[$j+1..$#out];
							@out = @out[0..$j-1];
							push @out,@tmp[4,5];
							push @out,@temp;
							@temp = @qvalue[$j+1..$#qvalue];
							@qvalue = @qvalue[0..$j-1];
							push @qvalue,@tmp[7,8];
							push @qvalue,@temp;
							last;
						}
					}
				}
				elsif(scalar @tmp == 7)# -- model  only linker
				{
					my $str = $tmp[4];
					$tmp[4] .= "#$tmp[5]";
					foreach my $j (0..$#out) {
						if($out[$j] eq $str)
						{
							$out[$j] = $tmp[4];
							$qvalue[$j] = $tmp[6];
							last;
						}
					}
				}
				else
				{
					print "it maybe have wenti3,check it\n";
					print "$_\t$tmp[$_]\n" foreach(0..$#tmp);
				}
			}
		}
		my $tt = (split /\s+/,$data[0])[0];
		print OUT "$tt\t$num\t".(join("\t",@out))."\t".(join("\t",@qvalue))."\n";
		return ($num,'yes');
	}
	else
	{
		print "it maybe have wenti4,check it\n";
	}
}


#4		0��linker				------
#7		ֻ��һ��linker			--
#9		һ��linker��һ������	--  ------or------ -- 
#11		ǰ�����У��м�linker����������	------  --  ------
