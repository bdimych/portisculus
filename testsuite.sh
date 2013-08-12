#!/bin/bash

set -e -o pipefail

tty=$(tty)
find ./testsuite -name run.sh | while read f
do
	echo - - - - - doing test: "$f" - - - - -
	"$f" <$tty
	echo test passed "$f"
	echo
done

echo testsuite succeeded!

