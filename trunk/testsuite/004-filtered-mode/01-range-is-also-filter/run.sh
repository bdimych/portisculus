#!/bin/bash

set -e -o pipefail

portDir=testsuite/004-filtered-mode/mp3/player-root/portisculus-1

# backup
cp -pv $portDir/alreadyInPlayer.txt .
ls -l $portDir | tee ls-before.txt

# the test
echo yyn | ./2-fill-player.rb -dbf testsuite/004-filtered-mode/mp3/dbf.txt -prd testsuite/004-filtered-mode/mp3/player-root/ -r172-174 -ob | tee 2-fill-log.txt

# clear and check
rm -fv $portDir/????-17{2,3,4}---*
cp -pv alreadyInPlayer.txt $portDir
ls -l $portDir | tee ls-after.txt
diff ls-before.txt ls-after.txt
rm -v alreadyInPlayer.txt ls-before.txt ls-after.txt 2-fill-log.txt

# ok!
echo success! test passed!

