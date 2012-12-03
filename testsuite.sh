#!/bin/bash

exec {runFiles}< <(find ./testsuite -name run.sh)
while read -u $runFiles f
do
	echo - - - - - doing test: $f - - - - -
	"$f" || exit 1
	echo
done
echo testsuite succeeded!

