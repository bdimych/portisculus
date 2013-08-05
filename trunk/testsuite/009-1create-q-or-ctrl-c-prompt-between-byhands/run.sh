#!/bin/bash

set -e -o pipefail

ffmpeg -n -f lavfi -i aevalsrc=0 -t 30 silence-30-sec.mp3
touch second-dummy-file.mp3


echo
echo = = = = = = = = = = = = = = = = = = = = check q = = = = = = = = = = = = = = = = = = = =
echo

echo silence-30-sec.mp3: byhands >dbf.txt
echo second-dummy-file.mp3: soundstretchFailed >>dbf.txt

{
	echo -n y
	sleep 10
	echo -n =
	sleep 1
	echo -n y
	sleep 3
	echo >&2
	tail -n 1 test-log.txt | grep -F 'press any key to continue or "q" or ctrl-c to quit' >&2
	echo -n q
} | ruby ./1-create-bpm-database.rb -dbf dbf.txt |& tee test-log.txt &

wait %1




echo
echo = = = = = = = = = = = = = = = = = = = = check int = = = = = = = = = = = = = = = = = = = =
echo




# sleep 2
# echo ps
# ps
# echo jobs
# jobs -l | tee jobs.txt
# sleep 14

# wait %1


	# else
		# read rubyPid rest < <(grep '[0-9]\+ \+| ruby ./1-create-bpm-database.rb' jobs.txt)
		# echo rubyPid is $rubyPid >&2
		# kill -INT $rubyPid
	# fi


rm -v silence-30-sec.mp3 second-dummy-file.mp3 dbf.txt test-log.txt

echo ok, $0 done

