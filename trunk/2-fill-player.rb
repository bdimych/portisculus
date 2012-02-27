#!/usr/bin/ruby


require 'lib.rb'


playerDir = 'test'
range = [150, 180]   # нужный диапазон bpm
maxCoef = 1.2        # максимальный коефициент на который можно менять bpm (по моим впечатлением больше 1.2 песня уже слух корябит - непохожа на саму себя)

best = false         # только лучшие песни
ARGV.each do |a|
	case a
		when '-b'
			best = true
		when '-g'
		else
			raise "unknown command line parameter \"#{a}\""
	end
end

best = ARGV[0] == 'best'   


p ARGV
exit


while true
	log 'main loop next iteration'
	$db.keys.shuffle.each do |f|
		next if ! f.bpmOk?
		log "doing #{f}"
	end
	sleep 1
end

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

=end

