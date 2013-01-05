#!/bin/bash

set -e -o pipefail

ruby ./1-create-bpm-database.rb -dbf testsuite/002-cygpath/dbf.txt 2>&1 | tee out.txt &
sleep 5

if uname | grep -i cygwin
then
	echo we are in cygwin
	expectedString="cygpath result: /cygdrive/d/Downloads/_ М У З Ы К А _/The Big Pink - Future This (2012) x/"
else
	echo we are probably in linux
	expectedString="db loaded: {:totalPaths=>2, :nonexistent=>2"
fi
echo output should contain "\"$expectedString\""
if ! grep -F "$expectedString" out.txt
then
	echo ERROR: wrong output
	exit 1
fi
echo ok

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

