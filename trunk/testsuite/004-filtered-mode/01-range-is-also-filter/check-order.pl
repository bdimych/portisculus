#!/usr/bin/perl

opendir p2, 'testsuite/004-filtered-mode/mp3/player-root/portisculus-2';
foreach (readdir p2) { # readdir returns filesystem order the same as "ls -U"
	print "$_\n"
}

