#!/usr/bin/ruby

require 'lib.rb'



# parsing command line

log 'parsing command line'

def usage errorMsg = nil
	if errorMsg
		puts
		puts "ERROR! #{errorMsg}"
	end
	puts <<e

options:
   -dbf /bpm/database/file.txt  (required)
   -pd /player/directory        (required)
e
	exit errorMsg ? 1 : 0
end
usage if ARGV.include? '--help'

require 'pathname'
while ! ARGV.empty?
	case a = ARGV.shift
		when /-dbf/
			$dbFile = ARGV.shift
		when '-pd'
			$playerDir = Pathname.new(ARGV.shift).cleanpath.to_s
	end
end
usage '-dbf must be specified' if ! $dbFile
usage "-dbf \"#$dbFile\" does not exist" if ! File.file? $dbFile
usage '-pd must be specified' if ! $playerDir
usage "-pd \"#$playerDir\" does not exist" if ! File.directory? $playerDir
log 'parsing done'

readDb
readAlreadyInPlayer

log "first files in the #{$playerDir}..."
system "ls -l --group-directories-first --color --file-type --time-style=long-iso '#$playerDir' | head"
exit if ! askYesNo '...is this a player directory? start ordering?'






srand

aip = []
best = []
beatless = []
$db.keys.shuffle.each do |f|
	if $db[f][:inPlayer]
		if f.best?
			best.push $db[f][:inPlayer]
		elsif f.beatless?
			beatless.push $db[f][:inPlayer]
		else
			aip.push $db[f][:inPlayer]
		end
	end
end

log 'calculating new order'
for i in 0..(aip.count-3)
	newNextInd = i + 1
	maxDiff = 0
	for j in (i+1)..(i+10)
		break if j == aip.count
		diff = aip[i][:bpm].to_i - aip[j][:bpm].to_i
		if diff.abs > maxDiff.abs
			maxDiff = diff
			newNextInd = j
		end
	end
	aip[i+1], aip[newNextInd] = aip[newNextInd], aip[i+1]
end

ordered = aip

if ! best.empty?
	log "inserting #{best.count} best songs evenly"
p	interval = (aip.count.to_f/(best.count+1)).round
	ordered = []
	for i in 0..(aip.count-1)
		ordered.push aip[i]
		if i > 0 and (i+1)%interval == 0 and ! best.empty?
p i
			ordered.push best.shift
		end
	end
	raise 'something went wrong: best is not empty after inserting' if ! best.empty?
	aip = ordered
end

ordered.each do |hash|
	p hash
end








