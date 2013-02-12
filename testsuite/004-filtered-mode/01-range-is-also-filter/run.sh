#!/bin/bash

set -e -o pipefail

portDir=testsuite/004-filtered-mode/mp3/player-root/portisculus-1

# backup
cp -prv $portDir{,-backup}
ls -l $portDir | tee ls-before.txt

exec 3>&1
# the test
{
	echo -n yy
	# если всё было правильно то сейчас 2-fill закончился и предлагает запустить 3-order
опс! неправильно!
действительно 2-fill получил два первых "yes" и пошёл дальше
но он НЕ ЗАКОНЧИЛСЯ ЗДЕСЬ
ОН ДАЛЬШЕ РАБОТАЕТ И ЗАКАНЧИВАЕТСЯ ЧЕРЕЗ КАКОЕ ТО ВРЕМЯ!
	echo blabla >&3
	sleep 1
	echo -n n
} | ruby ./2-fill-player.rb -dbf testsuite/004-filtered-mode/mp3/dbf.txt -prd testsuite/004-filtered-mode/mp3/player-root/ -r172-174 -ob | tee 2-fill-log.txt

# restore
rm -rfv $portDir
mv -v $portDir{-backup,}
# check restored
ls -l $portDir | tee ls-after.txt
diff ls-before.txt ls-after.txt
# clear
rm -v ls-before.txt ls-after.txt 2-fill-log.txt

# ok!
echo success! test passed!

