#!/bin/bash

set -e -o pipefail

ruby ./1-create-bpm-database.rb -dbf testsuite/002-cygpath/dbf.txt 2>&1 | tee out.txt &
sleep 9

function checkOutput {
	echo output should contain "\"$1\""
	if ! grep -F "$1" out.txt
	then
		echo ERROR: wrong output
		exit 1
	fi
	echo ok
}

if uname | grep -i cygwin
then
	echo we are in cygwin
	checkOutput "cygpath result: \"/cygdrive/d/Downloads/_ М У З Ы К А _/The Big Pink - Future This (2012) x/\""
	checkOutput "cygpath result: \"/cygdrive/d/Downloads/_ М У З Ы К А _/Super Dance Hits 90's - 2005 x\""
else
	echo we are probably in linux
	checkOutput "db loaded: {:totalPaths=>2, :nonexistent=>2"
fi

echo check background process is ended
jobs >jobs.txt
if ! grep 'Done.*1-create-bpm-database.rb' jobs.txt
then
	echo ERROR: unexpected \"jobs\" output:
	cat jobs.txt
	exit 1
fi
echo ok
echo delete temp files
rm -v out.txt jobs.txt
echo test done!

