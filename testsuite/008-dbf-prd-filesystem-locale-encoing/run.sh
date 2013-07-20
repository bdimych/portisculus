#!/bin/bash

function check {
	echo + + + + + check "$1" + + + + +

	dbf="testsuite/008-dbf-prd-filesystem-locale-encoing//$1.txt"
	prd="testsuite//008-dbf-prd-filesystem-locale-encoing/$1"
	rm -rfv "$dbf" "$prd"

	ruby 2-fill-player.rb -dbf "$dbf" -prd "$prd/" |& tee test-log.txt
	date >"$dbf"
	ruby ./2-fill-player.rb -dbf "./$dbf" -prd ".//$prd" |& tee test-log.txt
	mkdir "$prd"
	echo -n n | ruby 2-fill-player.rb -dbf ".//$dbf" -prd "$prd//" |& tee test-log.txt

	rm -rfv "$dbf" "$prd" test-log.txt

	echo
}

check 'Chinese 中国的'
check 'Hindi हिंदी'
check 'Russian Русский'

echo success

