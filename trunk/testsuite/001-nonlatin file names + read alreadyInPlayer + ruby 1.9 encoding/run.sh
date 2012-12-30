#!/bin/bash

set -e -o pipefail

if ruby -e 'exit Encoding.default_external == Encoding.find("filesystem")'
then
	echo \
'! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! !
WARNING! ruby says Encoding.default_external==Encoding.find("filesystem")
so on this system this test can not actually check encoding normalization in the lib.rb
! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! !'
fi

mydir=$(dirname "$0")
echo mydir is $mydir
portdir="$mydir/prd/portisculus-123"
echo portdir is $portdir

(
	cd "$portdir"
	rm -fv alreadyInPlayer.txt
	echo creating alreadyInPlayer.txt
	ls | sed 's/---\(.*\)/& < \1/' | { sleep 1; tee alreadyInPlayer.txt; } # на цигвине sleep ненужен а вот на линуксе оказалось "alreadyInPlayer.txt" видимо очень быстро создаётся и попадает в список ls
	echo wc alreadyInPlayer.txt
	wc alreadyInPlayer.txt
)

echo starting 2-fill-player.rb
echo y | ruby ./2-fill-player.rb -dbf "$mydir/dbf.txt" -prd "$mydir/prd" &> 2-fill-out.txt &
echo waiting for 2-fill-out.txt
for x in `seq 5`
do
	jobs
	ls -l 2-fill-out.txt
	sleep 1
done
echo looking for expected output
if ! grep '27 known files in player, checking other files' 2-fill-out.txt
then
	echo ERROR: could not find expected string
	cat 2-fill-out.txt
	echo ERROR: could not find expected string
	exit 1
fi
echo ok
echo checking background process is ended
jobs | tee jobs.txt
if [[ -s jobs.txt ]]
then
	echo ERROR: \"jobs\" has printed something
	exit 1
fi
echo ok
echo cleaning
rm -v "$portdir/alreadyInPlayer.txt" 2-fill-out.txt jobs.txt
echo test done!

