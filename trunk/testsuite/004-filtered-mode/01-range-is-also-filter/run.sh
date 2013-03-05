#!/bin/bash

set -e -o pipefail

portDir=testsuite/004-filtered-mode/mp3/player-root/portisculus-1
portDir2=testsuite/004-filtered-mode/mp3/player-root/portisculus-2

# backup
if [[ -d $portDir-backup ]]
then
	echo ERROR: $portDir-backup directory already exists
	exit 1
fi
cp -prv $portDir{,-backup}
ls -l $portDir | tee ls-before.txt



# run 2-fill
echo -n yyn | ruby ./2-fill-player.rb -dbf testsuite/004-filtered-mode/mp3/dbf.txt -prd testsuite/004-filtered-mode/mp3/player-root/ -r172-174 -ob | tee test-log.txt
ls -l $portDir | tee ls-test.txt
# check
for nameRegexp in \
	'0000-17[234]---01\. Different Reality\.mp3' \
	'0000-17[234]---03 - Малинки\.mp3' \
	'0000-17[234]---302 - Jack and the Rave_1\.mp3' \
	'0000-17[234]---0005-167---Banquet - Drunken sailor \[5\.10\] by Soul2soull\.mp3' \
	'0000-17[234]---0015-160---digital boy with asia - 01 - the mountain of king (radio edit) by Soul2soull\.mp3'
do
	echo - - - check "$nameRegexp" - - -
	echo in log
	grep "myCopyFile .*$portDir/$nameRegexp" test-log.txt
	echo in list
	grep "$nameRegexp" ls-test.txt
done
set -x
grep '5 added (2 recodedFromThePlayerDirItself):' test-log.txt
set +x



# restore
rm -rfv $portDir $portDir2
mv -v $portDir{-backup,}
# check restored
ls -l $portDir | tee ls-after.txt
diff ls-before.txt ls-after.txt
# clear
rm -v ls-before.txt ls-test.txt ls-after.txt test-log.txt

# ok!
echo success! test passed!

