#!/bin/bash

set -e -o pipefail

./1-create-bpm-database.rb -dbf testsuite/002-trailing-slash/dbf.txt 2>&1 | tee out.txt &
sleep 5

if uname | grep -i cygwin
then
	echo we are in cygwin, output should contain '"cygpath result: /cygdrive/d/Downloads/_ М У З Ы К А _/The Big Pink - Future This (2012) x/"'
	if ! grep -F 'cygpath result: /cygdrive/d/Downloads/_ М У З Ы К А _/The Big Pink - Future This (2012) x/' out.txt
	then
		echo ERROR: wrong output
		exit 1
	fi
	echo ok
else
	:
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

