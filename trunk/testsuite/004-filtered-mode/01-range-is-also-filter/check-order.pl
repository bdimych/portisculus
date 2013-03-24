#!/usr/bin/perl

my %firstFive = (
	'01. Different Reality.mp3' => 1,
	'03 - Малинки.mp3' => 1,
	'302 - Jack and the Rave_1.mp3' => 1,
	'Banquet - Drunken sailor [5.10] by Soul2soull.mp3' => 1,
	'digital boy with asia - 01 - the mountain of king (radio edit) by Soul2soull.mp3' => 1
);

opendir p2, 'testsuite/004-filtered-mode/mp3/player-root/portisculus-2';
my $i = -1;
foreach (readdir p2) { # readdir returns filesystem order the same as "ls -U"
	next if /^\./ or /alreadyInPlayer\.txt/;
	
	$i++;
	print "$i-th file $_\n";
	
	my ($num, $bpm, $name) = /(....)-(...)---(.*)/;
	
	if (sprintf('%04u', $i) ne $num) {
		die "file name does not start with $i"
	}
	if ($i < 5) { # first 5 - best songs with faster bpm
		if ($bpm < 172) {
			die 'bpm must be in the range 172-174'
		}
		if (! exists $firstFive{$name}) {
			die 'no such name in %firstFive'
		}
		delete $firstFive{$name}
	}
	else { # common songs and bpm
		if (%firstFive) { # а может ли такое вообще быть то??? если я до пятого каждый найденный удаляю то если было пять имён то ровно пять и удаляцца :) ну и хрен с ним оставлю хуже не будет :)
			die '%firstFive is not empty'
		}
		if ($bpm >= 172) {
			die 'fast bpm but must be common'
		}
	}
}
if ($i != 19) {
	die "total count of files is $i but must be 19"
}

