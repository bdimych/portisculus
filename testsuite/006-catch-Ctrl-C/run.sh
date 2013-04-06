#!/bin/bash

set -e -o pipefail

echo -n yyn | ruby 2-fill-player.rb -dbf testsuite/006-catch-Ctrl-C/dbf.txt -prd . -r 148-166

rm -rv portisculus-1

echo ok, test passed

