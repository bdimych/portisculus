#!/bin/bash

set -e -o pipefail

find ./testsuite -name run.sh | while read f
do
	echo - - - - - doing test: "$f" - - - - -
	"$f"
	echo test "$f" passed
	echo
done
echo testsuite succeeded!

