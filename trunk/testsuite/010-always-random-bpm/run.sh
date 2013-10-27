#!/bin/bash

set -e -o pipefail

echo -n yyn | ruby 2-fill-player.rb -dbf testsuite/010-always-random-bpm/база-бпм.txt -prd testsuite/010-always-random-bpm/плеер-рут -r100-200 | tee лог.текст

rm -rv testsuite/010-always-random-bpm/плеер-рут/portisculus-1 лог.текст

echo test ok

