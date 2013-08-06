#!/bin/bash

set -e -o pipefail

ffmpeg -n -f lavfi -i aevalsrc=0 -t 30 silence-30-sec.mp3
touch second-dummy-file.mp3

cygwin=
if uname | grep -i cygwin &>/dev/null
then
	cygwin=yes
fi

function simulateKey {
	key=$1
	if [[ $cygwin ]]
	then
		if [[ $key == = ]]
		then
			key=plus
		fi
		nircmd sendkeypress $key
	else
		:
	fi
}

echo
echo = = = = = = = = = = = = = = = = = = = = check int = = = = = = = = = = = = = = = = = = = =
echo

echo silence-30-sec.mp3: byhands >dbf.txt
echo second-dummy-file.mp3: soundstretchFailed >>dbf.txt

ruby ./1-create-bpm-database.rb -dbf dbf.txt |& tee test-log.txt &

sleep 6
simulateKey y
sleep 10
simulateKey =
sleep 1
simulateKey y
sleep 3
echo
tail -n 1 test-log.txt | grep -F 'press any key to continue or "q" or ctrl-c to quit'
sleep 2
simulateKey ctrl+c
															sleep 1
															simulateKey enter
sleep 3
jobs -l




# mkfifo test-input-fifo.txt
# ruby ./1-create-bpm-database.rb -dbf dbf.txt <test-input-fifo.txt &>test-log.txt &
# rubyPid=$!
# echo rubyPid is \"$rubyPid\"
# exec 3>test-input-fifo.txt
# tail -f test-log.txt &

# echo -n y >&3
# sleep 10
# echo -n = >&3
# sleep 1
# echo -n y >&3
# sleep 3
# echo
# tail -n 1 test-log.txt | grep -F 'press any key to continue or "q" or ctrl-c to quit'

# cmd="kill -INT $rubyPid"
# echo $cmd
# $cmd

# if uname | grep -i cygwin
# then
	# echo we are in the Cygwin
# else
	# echo we are not in the Cygwin
# fi

# exit




# echo
# echo = = = = = = = = = = = = = = = = = = = = check q = = = = = = = = = = = = = = = = = = = =
# echo

# echo silence-30-sec.mp3: byhands >dbf.txt
# echo second-dummy-file.mp3: soundstretchFailed >>dbf.txt

# {
	# echo -n y
	# sleep 10
	# echo -n =
	# sleep 1
	# echo -n y
	# sleep 3
	# echo >&2
	# tail -n 1 test-log.txt | grep -F 'press any key to continue or "q" or ctrl-c to quit' >&2
	# echo -n q
# } | ruby ./1-create-bpm-database.rb -dbf dbf.txt |& tee test-log.txt &

# wait %1




rm -v silence-30-sec.mp3 second-dummy-file.mp3 dbf.txt test-log.txt

echo ok, $0 done

