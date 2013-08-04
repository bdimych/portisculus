#!/bin/bash

set -e -o pipefail

ffmpeg -n -f lavfi -i aevalsrc=0 -t 30 silence-30-sec.mp3
touch second-dummy-file.mp3
echo silence-30-sec.mp3: byhands >dbf.txt
echo second-dummy-file.mp3: soundstretchFailed >>dbf.txt

mkfifo fifo.txt
ruby ./1-create-bpm-database.rb -dbf dbf.txt <fifo.txt |& tee test-log.txt &
testCmdPid=$!

sleep 3
echo $!
ps
sleep 3
{
	echo -n y
	sleep 10
	echo -n =y
} >fifo.txt

set -x
jobs -l
wait $testCmdPid
echo $?

rm -v silence-30-sec.mp3 second-dummy-file.mp3 dbf.txt fifo.txt test-log.txt

echo ok, $0 done

