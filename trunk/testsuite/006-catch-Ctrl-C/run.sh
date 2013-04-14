#!/bin/bash

set -e -o pipefail

function myRun {
	echo -n yyn | ruby $* -dbf testsuite/006-catch-Ctrl-C/dbf.txt -prd . -r 148-166 | tee test-log.txt
}

echo first run
myRun 2-fill-player.rb
msgCount=$(sed -n '/preparing for adding loop/,/---- at_exit ok -----/p' test-log.txt | grep '^\[' | wc -l)
echo msgCount is $msgCount
if (( $msgCount < 65 ))
then
	echo ERROR: log is too short $msgCount lines
	exit 1
fi
echo check test-log.txt 1
grep '^3 added (0 tempCopy):$' test-log.txt
[[ $(ls portisculus-1/*.mp3 | wc -l) == 3 ]]

rm -rv portisculus-1 test-log.txt

echo second slow run
myRun testsuite/006-catch-Ctrl-C/2fill-wrapper.rb $msgCount
echo check test-log.txt 2
grep 'exit cause of Ctrl-C was caught$' test-log.txt
grep '^2-fill finished correctly$' test-log.txt
grep -- '------------------------------ at_exit ok ------------------------------$' test-log.txt
grep -- '- - - - - - - - - - - - - - - - - - - - - - - - - !!! Ctrl-C caught !!! - will stop at the nearest appropriate moment$' test-log.txt

rm -rv portisculus-1 test-log.txt

echo ok, test passed

