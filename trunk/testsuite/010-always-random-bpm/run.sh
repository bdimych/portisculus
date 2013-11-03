#!/bin/bash

set -e -o pipefail

echo -n yyn | ruby 2-fill-player.rb -dbf testsuite/010-always-random-bpm/база-бпм.txt -prd testsuite/010-always-random-bpm/плеер-рут -r100-200 -arbpm | tee лог.текст

set -x
[[ $(grep 'get new bpm because arbpm flag is set' лог.текст | wc -l) == 3 ]]
[[ $(grep '^\[.\+\] ffmpeg -nostdin -y -i tmp.mp3 -ab 128k -af atempo=.\+ tmp-result.mp3$' лог.текст | wc -l) == 3 ]]
set +x

rm -rv testsuite/010-always-random-bpm/плеер-рут/portisculus-1 лог.текст

echo test ok

