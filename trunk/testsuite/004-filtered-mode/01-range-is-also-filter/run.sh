#!/bin/bash

set -e -o pipefail

portDir=testsuite/004-filtered-mode/mp3/player-root/portisculus-1
portDir2=testsuite/004-filtered-mode/mp3/player-root/portisculus-2

# backup
cp -prv $portDir{,-backup}
ls -l $portDir | tee ls-before.txt

echo -n yyyy | ruby ./2-fill-player.rb -dbf testsuite/004-filtered-mode/mp3/dbf.txt -prd testsuite/004-filtered-mode/mp3/player-root/ -r172-174 -ob | tee test-log.txt
ls -U $portDir2 | tee ls-test.txt

# restore
rm -rfv $portDir2
mv -v $portDir{-backup,}
# check restored
ls -l $portDir | tee ls-after.txt
diff ls-before.txt ls-after.txt
# clear
rm -v ls-before.txt ls-test.txt ls-after.txt test-log.txt

# ok!
echo success! test passed!

