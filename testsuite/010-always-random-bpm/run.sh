#!/bin/bash

set -e -o pipefail

ruby 2-fill-player.rb -dbf testsuite/010-always-random-bpm/база-бпм.txt -prd testsuite/010-always-random-bpm/плеер-рут

rm -rv testsuite/010-always-random-bpm/плеер-рут/portisculus-1

