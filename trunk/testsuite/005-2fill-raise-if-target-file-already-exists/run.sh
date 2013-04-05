#!/bin/bash

set -e -o pipefail

mkdir portisculus-1

trgFile='./portisculus-1/0000-BLS---Уже есть такой файл Mexico JD.mp3'

function runAndCheck {
	ls -l portisculus-1
	if echo ynyn | ruby 2-fill-player.rb -prd . -dbf ./testsuite/005-2fill-raise-if-target-file-already-exists/dbf.txt | tee test-log.txt
	then
		echo ERROR: 2fill succeeded but it should fail
		exit 1
	fi
	echo check test-log.txt
	grep -F "#<RuntimeError: target file $trgFile already exists>" test-log.txt
	echo ok
}

echo - - - symlink - - -
ln -s /dev/null "$trgFile"
runAndCheck
rm -v "$trgFile"

echo - - - fifo - - -
mkfifo "$trgFile"
cat "$trgFile" >/dev/null & # если 2fill неправильный то он начнёт записывать и подвиснет если из fifo никто не читает
runAndCheck
echo >"$trgFile" # а если 2fill правильный то он ошибся и вышел а cat сейчас висит и надо её завершить
sleep 1
jobs # напишет что-то типа "[1]+ Done cat...."
jobs | tee jobs.txt # а второй jobs уже должен быть пустой вывод
if [[ -s jobs.txt ]]
then
	echo ERROR: jobs.txt is not empty
	exit 1
fi
rm -v "$trgFile"

echo - - - folder - - -
mkdir -v "$trgFile"
runAndCheck
rmdir -v "$trgFile"

echo - - - common file - - -
touch "$trgFile"
runAndCheck

rm -rv portisculus-1 test-log.txt jobs.txt

echo success!

