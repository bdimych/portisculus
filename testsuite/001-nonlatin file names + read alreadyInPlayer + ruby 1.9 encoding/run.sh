#!/bin/bash

set -e -o pipefail

mydir=$(dirname "$0")
echo mydir is $mydir
portdir="$mydir/prd/portisculus-123"
echo portdir is $portdir

(
	cd "$portdir"
	rm -fv alreadyInPlayer.txt
	ls | sed 's/---\(.*\)/& < \1/' | tee alreadyInPlayer.txt
	wc alreadyInPlayer.txt
)

# TODO: проверить что енкодинги filesystem и по умолчанию не совпадают
echo y | ruby ./2-fill-player.rb -dbf "$mydir/dbf.txt" -prd "$mydir/prd" |& tee 2-fill-out.txt &
for x in `seq 10`
do
	sleep 1
	ls -l 2-fill-out.txt
done

