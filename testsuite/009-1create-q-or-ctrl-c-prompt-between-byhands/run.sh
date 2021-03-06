#!/bin/bash

set -e -o pipefail



cygwin=
if uname | grep -i cygwin &>/dev/null
then
	echo we are in cygwin
	cygwin=yes
else
	echo we are in linux
fi



if [[ $cygwin ]]
then
	gcc testsuite/009-1create-q-or-ctrl-c-prompt-between-byhands/printForegroundWindowTitle.c -o printForegroundWindowTitle.exe
fi
function printForegroundWindowTitle {
	if [[ $cygwin ]]
	then
		./printForegroundWindowTitle.exe
	else
		xdotool getactivewindow getwindowname
	fi
}

myWinTitle='xterm portisculus test 009'
echo -ne "\e]0;$myWinTitle\a" # set xterm window title
function makeTerminalForeground {
	while [[ $(printForegroundWindowTitle) != $myWinTitle ]]
	do
		echo we are not in the foreground
		testsuite/009-1create-q-or-ctrl-c-prompt-between-byhands/msgboxWithTimeout.tk
		sleep 2
	done
}



function simulateKey {
	makeTerminalForeground
	key=$1
	if [[ $cygwin ]]
	then
		[[ $key == = ]] && key=plus
		nircmd sendkeypress $key
	else # linux
		[[ $key == = ]] && key=KP_Equal
		[[ $key == enter ]] && key=Return
		xdotool key $key
	fi
}



ffmpeg -n -f lavfi -i aevalsrc=0 -t 30 silence-30-sec.mp3
touch second-dummy-file.mp3



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
kill -INT %+
sleep 2
echo jobs
jobs -l >jobs.txt
cat jobs.txt

# check jobs.txt
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
	if [[ -s jobs.txt ]]
	then
		echo jobs.txt is not empty
		exit 1
	fi
fi

# check log
set -x
grep '^\[at_exit\] \[[0-9:.]\+\] the end: Interrupt$' test-log.txt
grep 'lib\.rb:[0-9]\+:in .sysread.: Interrupt$' test-log.txt
grep 'from '"$(pwd)"'/lib\.rb:[0-9]\+:in .readChar.$' test-log.txt
tail -n1 test-log.txt | grep "from ./1-create-bpm-database.rb:[0-9]\+:in .<main>."
set +x



echo
echo = = = = = = = = = = = = = = = = = = = = check q = = = = = = = = = = = = = = = = = = = =
echo

echo silence-30-sec.mp3: byhands >dbf.txt
echo second-dummy-file.mp3: soundstretchFailed >>dbf.txt

ruby 1-create-bpm-database.rb -dbf dbf.txt |& tee test-log.txt &

sleep 4
simulateKey y
sleep 7
simulateKey =
sleep 1
simulateKey y
sleep 3
echo
tail -n 1 test-log.txt | grep -F 'press any key to continue or "q" or ctrl-c to quit'
sleep 2
simulateKey q
sleep 2
echo jobs
jobs -l >jobs.txt
cat jobs.txt

# check
set -x
grep 'Done \+ruby 1-create-bpm-database.rb -dbf dbf.txt' jobs.txt
tail -n1 test-log.txt | grep '^\[at_exit\] \[.\+\] the end: #<SystemExit: exit>$'
set +x



rm -v silence-30-sec.mp3 second-dummy-file.mp3 dbf.txt test-log.txt jobs.txt
[[ $cygwin ]] && rm -v printForegroundWindowTitle.exe

echo ok, $0 done



