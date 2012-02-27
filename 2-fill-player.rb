#!/usr/bin/ruby


require 'lib.rb'



=begin
bpmDb=../bdimych.txt/bpm-database.txt
playerDir=test

set -e -o pipefail



trap atexit EXIT
function atexit {
	echo atexit
}


while true
do
	echo main loop next iteration
	shuf "$bpmDb" | while IFS=: read line
	do
		echo $line
		if [[ $line =~ ^([-+=])?\ *(.+):\ *([0-9]+)? ]]
		then
			flag=${BASH_REMATCH[1]}
			path="${BASH_REMATCH[2]}"
			bpm=${BASH_REMATCH[3]}
			
		else
			echo seems is not mp3
		fi
		sleep 3
	done
	read -p 'press Enter2'
done

=cut