#!/bin/bash

while read f
do
	echo - - - - - doing test: $f - - - - -
	"$f" || exit 1
	echo
done < <(find ./testsuite -name run.sh)

echo testsuite succeeded!

