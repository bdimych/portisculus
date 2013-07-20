#!/bin/bash

function check {
	echo + + + + + check "$1" + + + + +

	dbf="testsuite/008-dbf-prd-filesystem-locale-encoing//$1.txt"
	prd="testsuite//008-dbf-prd-filesystem-locale-encoing/$1"
	rm -rfv "$dbf" "$prd"

	ruby 2-fill-player.rb -dbf "$dbf" -prd "$prd/" |& tee test-log-1.txt
	date >"$dbf"
	ruby ./2-fill-player.rb -dbf "./$dbf" -prd ".//$prd" |& tee test-log-2.txt
	mkdir "$prd"
	echo -n n | ruby 2-fill-player.rb -dbf ".//$dbf" -prd "$prd//" |& tee test-log-3.txt

	# checks
	cleanPath="testsuite/008-dbf-prd-filesystem-locale-encoing/$1"
	set -ex
	# 1
	grep -Fx "ERROR! -dbf \"$cleanPath.txt\" does not exist" test-log-1.txt
	grep -Fx options: test-log-1.txt
	# 2
	grep -F "database file $cleanPath.txt" test-log-2.txt
	grep -Fx "ERROR! -prd \"$cleanPath\" does not exist" test-log-2.txt
	grep -Fx options: test-log-2.txt
	# 3
	grep -F "database file $cleanPath.txt" test-log-3.txt
	grep -F 'player root directory:' test-log-3.txt
	grep -Fx "[$cleanPath:" test-log-3.txt
	grep -Fx "there is no portisculus directory in player root so going to create \"$cleanPath/portisculus-1\", proceed? (Y, n) n" test-log-3.txt
	set +ex

	rm -rfv "$dbf" "$prd" test-log-*.txt

	echo
	echo + + + + + "$1" - ok
	echo
}

check 'Chinese 中国的'
check 'Russian Русский'
#check 'Hindi हिंदी'

echo success

