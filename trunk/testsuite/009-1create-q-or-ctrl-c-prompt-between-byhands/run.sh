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
kill -INT %1
sleep 2
echo jobs
jobs -l >jobs.txt
cat jobs.txt

if [[ $cygwin ]]
then
	if grep 'Running \+ruby' jobs.txt
	then
		simulateKey enter
		sleep 2
		echo jobs after Enter
		jobs -l >jobs.txt
		cat jobs.txt
		if [[ -s jobs.txt ]]
		then
			echo jobs.txt is not empty
			exit 1
		fi
	else
		echo WARNING: it seems that the https://bugs.ruby-lang.org/issues/8708 is now fixed, please modify this test accordingly
		exit 1
	fi

else # linux
	:
fi

set -x
grep '^\[at_exit\] \[[0-9:.]\+\] the end: Interrupt$' test-log.txt
grep 'lib\.rb:[0-9]\+:in .sysread.: Interrupt$' test-log.txt
grep 'from '"$(pwd)"'/lib\.rb:[0-9]\+:in .readChar.$' test-log.txt
tail -n1 test-log.txt | grep "from ./1-create-bpm-database.rb:[0-9]\+:in .<main>."
set +x



rm -v silence-30-sec.mp3 second-dummy-file.mp3 dbf.txt test-log.txt jobs.txt

echo ok, $0 done

