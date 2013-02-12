#!/bin/bash

set -e -o pipefail

portDir=testsuite/004-filtered-mode/mp3/player-root/portisculus-1

# backup
cp -prv $portDir{,-backup}
ls -l $portDir | tee ls-before.txt

# the test
echo yyn | ./2-fill-player.rb -dbf testsuite/004-filtered-mode/mp3/dbf.txt -prd testsuite/004-filtered-mode/mp3/player-root/ -r172-174 -ob | tee 2-fill-log.txt

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

