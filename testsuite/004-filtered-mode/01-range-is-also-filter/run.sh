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
# новые добавились
for nameRegexp in \
	'0000-17[234]---01\. Different Reality\.mp3' \
	'0000-17[234]---03 - Малинки\.mp3' \
	'0000-17[234]---302 - Jack and the Rave_1\.mp3' \
	'0000-17[234]---Banquet - Drunken sailor \[5\.10\] by Soul2soull\.mp3' \
	'0000-17[234]---digital boy with asia - 01 - the mountain of king (radio edit) by Soul2soull\.mp3'
do
	echo ==================== check regexp $nameRegexp ====================
	echo in log
	grep "myCopyFile .*$portDir/$nameRegexp" test-log.txt
	echo in player
	grep "$nameRegexp" ls-test.txt
done
set -x
# старые остались
grep -F '0001-168---03 - Малинки.mp3' ls-test.txt
grep -F '0008-166---302 - Jack and the Rave_1.mp3' ls-test.txt
# статистика в логе
grep '5 added (4 tempCopy):' test-log.txt
grep 'saved, 20 lines' test-log.txt
# в логе 4 вызова makeTempCopy
# 2 NEMOOR
grep -F 'makeTempCopy /no such path/Eurodance music/Banquet - Drunken sailor [5.10] by Soul2soull.mp3, testsuite/004-filtered-mode/mp3/player-root/portisculus-1/0005-167---Banquet - Drunken sailor [5.10] by Soul2soull.mp3, {:bpm=>"167", :flag=>"+"}' test-log.txt
grep -F 'makeTempCopy /no such path/Eurodance music/digital boy with asia - 01 - the mountain of king (radio edit) by Soul2soull.mp3, testsuite/004-filtered-mode/mp3/player-root/portisculus-1/0015-160---digital boy with asia - 01 - the mountain of king (radio edit) by Soul2soull.mp3, {:bpm=>"160", :flag=>"+"}' test-log.txt
# 2 EOOR
grep -F 'makeTempCopy testsuite/004-filtered-mode/mp3/best/03 - Малинки.mp3, testsuite/004-filtered-mode/mp3/best/03 - Малинки.mp3, {:bpm=>"132", :flag=>"+"}' test-log.txt
grep -F 'makeTempCopy testsuite/004-filtered-mode/mp3/best/302 - Jack and the Rave_1.mp3, testsuite/004-filtered-mode/mp3/best/302 - Jack and the Rave_1.mp3, {:bpm=>"143", :flag=>"+"}' test-log.txt
# содержимое tempCopy/
find tempCopy/ | grep -F 'tempCopy/no such path/Eurodance music/Banquet - Drunken sailor [5.10] by Soul2soull.mp3'
find tempCopy/ | grep -F 'tempCopy/no such path/Eurodance music/digital boy with asia - 01 - the mountain of king (radio edit) by Soul2soull.mp3'
find tempCopy/ | grep -F 'tempCopy/testsuite/004-filtered-mode/mp3/best/03 - Малинки.mp3'
find tempCopy/ | grep -F 'tempCopy/testsuite/004-filtered-mode/mp3/best/302 - Jack and the Rave_1.mp3'
# alreadyInPlayer.txt
grep -P '0000-17[234]\Q---01. Different Reality.mp3 < testsuite/004-filtered-mode/mp3/best/01. Different Reality.mp3' $portDir/alreadyInPlayer.txt
grep -P '0000-17[234]\Q---Banquet - Drunken sailor [5.10] by Soul2soull.mp3 < tempCopy//no such path/Eurodance music/Banquet - Drunken sailor [5.10] by Soul2soull.mp3' $portDir/alreadyInPlayer.txt
grep -P '0000-17[234]\Q---digital boy with asia - 01 - the mountain of king (radio edit) by Soul2soull.mp3 < tempCopy//no such path/Eurodance music/digital boy with asia - 01 - the mountain of king (radio edit) by Soul2soull.mp3' $portDir/alreadyInPlayer.txt
grep -P '0000-17[234]\Q---03 - Малинки.mp3 < tempCopy/testsuite/004-filtered-mode/mp3/best/03 - Малинки.mp3' $portDir/alreadyInPlayer.txt
grep -P '0000-17[234]\Q---302 - Jack and the Rave_1.mp3 < tempCopy/testsuite/004-filtered-mode/mp3/best/302 - Jack and the Rave_1.mp3' $portDir/alreadyInPlayer.txt
# в логе в самом конце предложение запустить 3-order
orderCmd="'./3-order-files-in-player.rb' '-dbf' 'testsuite/004-filtered-mode/mp3/dbf.txt' '-prd' 'testsuite/004-filtered-mode/mp3/player-root' '-ob' '-r' '172-174'"
tail test-log.txt | grep -F "do you want to run [$orderCmd]"
set +x

# run 3-order
echo -n y | eval ruby $orderCmd | tee test-log.txt
# checks
if [[ -d $portDir ]]
then
	echo ERROR: $portDir directory still exists after 3-order
	exit 1
fi
set -x
grep -F 'tempCopy file found in player: tempCopy//no such path/Eurodance music/Banquet - Drunken sailor [5.10] by Soul2soull.mp3' test-log.txt
grep -F 'tempCopy file found in player: tempCopy//no such path/Eurodance music/digital boy with asia - 01 - the mountain of king (radio edit) by Soul2soull.mp3' test-log.txt
grep -F 'tempCopy file found in player: tempCopy/testsuite/004-filtered-mode/mp3/best/03 - Малинки.mp3' test-log.txt
grep -F 'tempCopy file found in player: tempCopy/testsuite/004-filtered-mode/mp3/best/302 - Jack and the Rave_1.mp3' test-log.txt
tail test-log.txt | grep -F 'files ordered!'
tail test-log.txt | grep -F 'saved, 20 lines'
# правильность составления массивов filtered и rest
cat  test-log.txt | grep -F -A2 'insertEvenly filtered, common, best, result'     | grep -F 'insertEvenly end: base.count: 0, ins.count: 5, interval: 0, res.count: 5'
cat  test-log.txt | grep -F -A2 'insertEvenly filtered, result, beatless, result' | grep -F 'insertEvenly end: base.count: 5, ins.count: 0, interval: 5, res.count: 5'
cat  test-log.txt | grep -F -A2 'insertEvenly rest, common, best, result'         | grep -F 'insertEvenly end: base.count: 9, ins.count: 0, interval: 2, res.count: 13'
cat  test-log.txt | grep -F -A2 'insertEvenly rest, result, beatless, result'     | grep -F 'insertEvenly end: base.count: 15, ins.count: 0, interval: 4, res.count: 15'
./testsuite/004-filtered-mode/01-range-is-also-filter/check-order.pl
set +x




# restore
rm -rv $portDir2
mv -v $portDir{-backup,}
# check restored
ls -l $portDir | tee ls-after.txt
diff ls-before.txt ls-after.txt
# clear
rm -v ls-before.txt ls-test.txt ls-after.txt test-log.txt

# ok!
echo success! test passed!

