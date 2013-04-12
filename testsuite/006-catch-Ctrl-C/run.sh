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
echo check test-log.txt
grep '^3 added (0 tempCopy):$' test-log.txt
[[ $(ls portisculus-1/*.mp3 | wc -l) == 3 ]]

rm -rv portisculus-1 test-log.txt

echo second slow run
myRun testsuite/006-catch-Ctrl-C/2fill-wrapper.rb $msgCount

rm -rv portisculus-1 test-log.txt

echo ok, test passed

