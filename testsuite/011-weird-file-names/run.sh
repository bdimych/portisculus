#!/bin/bash

set -e -o pipefail

rm -rfv portisculus-1
echo -n yyn | ruby 2-fill-player.rb -dbf ./testsuite/011-weird-file-names/-dbf.txt -prd .

set -x
[[ $(ls portisculus-1 | wc -l) == 6 ]]
[[ $(cat portisculus-1/alreadyInPlayer.txt | wc -l) == 5 ]]

rm -rv portisculus-1

echo -OK -$0

