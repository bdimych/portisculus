#!/bin/bash

set -e -o pipefail

mkdir portisculus-1

trgFile='portisculus-1/0000-BLS---Уже есть такой файл Mexico JD.mp3'

function runAndCheck {
	if echo ynyn | ruby 2-fill-player.rb -prd . -dbf ./testsuite/005-2fill-raise-if-target-file-already-exists/dbf.txt | tee test-log.txt
	then
		echo ERROR: 2fill should fail but it succeeded
		exit 1
	fi
	echo check test-log.txt
	grep -F "target file $trgFile already exists" test-log.txt
	echo ok
}

echo - - - symlink - - -
ln -s linked.mp3 "$trgFile"
runAndCheck

echo - - - fifo - - -

echo - - - folder - - -

echo - - - common file - - -

rm -rfv portisculus-1 test-log.txt

echo success!

