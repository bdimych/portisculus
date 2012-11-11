#!/bin/bash

find ./testsuite -name run.sh | while read f
do
	echo - - - - - doing test: $f - - - - -
	"$f" || exit 1
	echo
done

echo testsuite succeeded!

