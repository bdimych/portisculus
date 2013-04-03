#!/bin/bash

set -e -o pipefail

mkdir portisculus-1

# symlink
ln -s ./linked.mp3 'portisculus-1/0000-BLS---Уже есть такой файл Mexico JD.mp3'
echo ynyn | ruby 2-fill-player.rb -prd . -dbf ./testsuite/005-2fill-raise-if-target-file-already-exists/dbf.txt

# fifo
# folder
# common file

rm -rfv portisculus-1

echo success!

