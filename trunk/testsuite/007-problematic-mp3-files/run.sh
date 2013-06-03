#!/bin/bash

set -e -o pipefail

dbf=$0.dbf.txt

cat >$dbf <<dbf
`pwd`/testsuite/007-problematic-mp3-files/mp3/02 - Gmo - Koiau (Exclusive Track).mp3	:141
`pwd`/testsuite/007-problematic-mp3-files/mp3/04. Communiqué.mp3											:byhands
`pwd`/testsuite/007-problematic-mp3-files/mp3/06 - Mantrix - Gaia.mp3									:142
testsuite/007-problematic-mp3-files/mp3/10 - Cosma - Time Has Come.mp3								:143
testsuite/007-problematic-mp3-files/mp3/11. Недетское Время.mp3												:byhands
testsuite/007-problematic-mp3-files/mp3/13 - S.u.n. Project - Hangin' Around.mp3			:144
`pwd`/testsuite/007-problematic-mp3-files/mp3/13.DJ Sim - Happy Organ.mp3							:145
testsuite/007-problematic-mp3-files/mp3/17 - Psypsiq Jiouri - Histora De Un Sueno.mp3	:146
`pwd`/testsuite/007-problematic-mp3-files/mp3/19 - Syn Sun - Ceremony.mp3							:147
dbf



# subtest 1
echo subtest 1
perl -e '
	$| = 1;
	print "l\r";
	sleep 6;
	for (1..2) {
		for (1..75) {
			print " ";
			select undef, undef, undef, 0.5
		}
		sleep 1;
		print "d\n\r";
		sleep 3
	}
' | ruby ./1-create-bpm-database.rb -dbf $dbf 2>&1 | tee test-log.txt
# check
set -x
grep -F '2 files remains without bpm, count them by hands (Y, n, (l)ist)? y' test-log.txt
grep -F "[byhands] $(pwd)/testsuite/007-problematic-mp3-files/mp3/04. Communiqué.mp3" test-log.txt
grep -F '[byhands] testsuite/007-problematic-mp3-files/mp3/11. Недетское Время.mp3' test-log.txt
grep -P '^\QPlaying 04. Communiqué.mp3.' test-log.txt
grep -P '^\QPlaying 11. Недетское Время.mp3.' test-log.txt
[[ $(grep '^Starting playback...$' test-log.txt | wc -l) == 2 ]]
[[ $(grep -P '^Counter:  74;   seconds: 37;   bpm: 1(19|20|21);   average bpm result: 1(19|20)$' test-log.txt | wc -l) == 2 ]]
[[ $(grep '^Exiting... (Quit)$' test-log.txt | wc -l) == 2 ]]
[[ $(grep -P 'by hands result: "1(19|20)"$' test-log.txt | wc -l) == 2 ]]
[[ $(grep -P '^bpm = 1(19|20)$' test-log.txt | wc -l) == 2 ]]
tail -n2 test-log.txt | grep -F 'skip writing, db was not changed: {:totalPaths=>9, :nonexistent=>0, :dirs=>0, :files=>9, :best=>0, :beatless=>0, :skipped=>0, :withoutBpm=>0, :canBeAdded=>9}'
tail -n2 test-log.txt | grep -F 'the end: nil'
grep -P '04. Communiqué.mp3: 1(19|20)$' $dbf
grep -P '11. Недетское Время.mp3: 1(19|20)$' $dbf
set +x
echo ok, subtest 1 done



# subtest 2
echo subtest 2
prd=$(dirname $0)/prd
mkdir $prd
echo -n yyn | ruby 2-fill-player.rb -dbf $dbf -prd $prd |& tee test-log.txt
# check
set -x
grep '^there is no portisculus directory in player root so going to create' test-log.txt
grep 'doing file . of 9 (added .): testsuite/007-problematic-mp3-files/mp3/13.DJ Sim - Happy Organ.mp3' -A2 test-log.txt | grep -F '227 sec (3 min 47 sec) - ok'
grep -F -- '------------------------------ at_exit ok ------------------------------' test-log.txt
grep '^9 added (0 tempCopy):$' test-log.txt
grep '^0 tooLong:$' test-log.txt
[[ $(wc -l $prd/portisculus-1/alreadyInPlayer.txt) == 9 ]]
set +x



rm -rv $dbf $prd test-log.txt

echo ok! test done! ':)'


