#!/bin/bash

set -xe -o pipefail

mkdir portisculus-1

echo yn | ruby ./2-fill-player.rb -dbf testsuite/003-filter-regexp-utf8/dbf.txt -re отцы -prd . 2>&1 | tee out.txt
set +x
echo check output
if ! {
	grep 'regexp and/or -ob was specified, 1 files matched' out.txt &&
	grep '/cygdrive/d/Downloads/_ М У З Ы К А _/Diskoteka_Avariya-Diskografia/Альбомы и синглы/2008 - The Best/01 Отцы.mp3' out.txt &&
	grep 'num of files to add:     all of 1$' out.txt
}
then
	echo ERROR: could not find expected strings
	exit 1
fi

rmdir portisculus-1
rm out.txt

echo ✔ ok! test passed!

