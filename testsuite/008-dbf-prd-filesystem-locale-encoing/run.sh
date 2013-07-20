#!/bin/bash

set -x
{
	ruby 2-fill-player.rb -dbf 'testsuite//008-utf8-dbf-prd/chinese 中國的.txt'
	ruby 2-fill-player.rb -dbf 'testsuite//008-utf8-dbf-prd/chinese 中国的.txt'
	ruby 2-fill-player.rb -dbf 'testsuite//008-utf8-dbf-prd/russian русский.txt'
} | tee test-log.txt

rm test-log.txt

echo success

