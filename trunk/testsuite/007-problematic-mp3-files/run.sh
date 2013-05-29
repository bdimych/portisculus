#!/bin/bash

set -e -o pipefail

dbf=$0.dbf.txt

cat >$dbf <<dbf
testsuite/007-problematic-mp3-files/mp3/02 - Gmo - Koiau (Exclusive Track).mp3				:141
testsuite/007-problematic-mp3-files/mp3/04. Communiqué.mp3														:byhands
testsuite/007-problematic-mp3-files/mp3/06 - Mantrix - Gaia.mp3												:142
testsuite/007-problematic-mp3-files/mp3/10 - Cosma - Time Has Come.mp3								:143
testsuite/007-problematic-mp3-files/mp3/11. Недетское Время.mp3												:byhands
testsuite/007-problematic-mp3-files/mp3/13 - S.u.n. Project - Hangin' Around.mp3			:144
testsuite/007-problematic-mp3-files/mp3/13.DJ Sim - Happy Organ.mp3										:145
testsuite/007-problematic-mp3-files/mp3/17 - Psypsiq Jiouri - Histora De Un Sueno.mp3	:146
testsuite/007-problematic-mp3-files/mp3/19 - Syn Sun - Ceremony.mp3										:147
dbf

					dbf=tmp.txt
					echo 'testsuite/007-problematic-mp3-files/mp3/19 - Syn Sun - Ceremony.mp3: byhands' >$dbf

perl -e '$| = 1; print "l\r"; sleep 6; for (1..75) {print " "; select undef, undef, undef, 0.5} sleep 2; print "d\n\r"' | ruby ./1-create-bpm-database.rb -dbf $dbf 2>&1 | tee test-log.txt

rm -v $dbf                               # test-log.txt

echo ok! test done! ':)'

