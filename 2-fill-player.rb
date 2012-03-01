#!/usr/bin/ruby


require 'lib.rb'




playerDir = 'test'
range = [150, 180]   # нужный диапазон bpm
maxCoef = 1.2        # максимальный коефициент на который можно менять bpm. По моим впечатлением больше 1.2 песня уже слух корябит - становится непохожа на саму себя
bestOnly = false     # только лучшие песни
groupBy = nil
grep = nil





# parsing command line

log 'parsing command line'

def usage errorMsg = nil
	if errorMsg
		puts
		puts "ERROR! #{errorMsg}"
	end
	puts <<e

possible options:
   -b           - only best songs
   -gd          - group target files by source directories
   -gb          - group by bpm
   -r NNN-NNN   - needed bpm range
   -pd /player/directory
   remaining argument will be used as regular expression and only matched files will be copied
e
	exit errorMsg ? 1 : 0
end

usage if ARGV.include? '--help'
while ! ARGV.empty?
	case a = ARGV.shift
		when '-b'
			bestOnly = true
		when '-gd', '-gb'
			if groupBy
				usage '-gd and -gb are mutually exclusive'
			end
			groupBy = a == '-gd' ? :dir : :bpm
		when '-r'
			if ARGV.shift =~ /^(\d+)-(\d+)$/
				range = [$1.to_i, $2.to_i]
				if range[0] > range[1]
					usage 'first value in range is greater then second'
				end
			else
				usage 'range is specified incorrectly - should be "number-number"'
			end
		when '-pd'
			playerDir = ARGV.shift
		else
			grep = a
	end
end
playerDir = File::expand_path playerDir
usage "player directory #{playerDir} does not exist" if ! File.directory? playerDir
log 'parsing done'

puts
files = $db.keys.sort.select do |path|
	ok = path.canBeCopied?
	ok &&= path.match Regexp.new grep, Regexp::IGNORECASE if grep
	ok &&= path.best? if bestOnly
	ok
end
if grep or bestOnly
	puts "#{files.size} files found:"
	puts '-----'
	files.map {|f| puts f}
	puts '-----'
	puts "#{files.size} files found"
	puts
end
puts <<e
player directory:        #{playerDir}
needed bpm range:        #{range[0]}-#{range[1]}
only best songs:         #{bestOnly ? 'yes' : 'no'}
group target files by:   #{
	case groupBy
		when :dir then 'source directories'
		when :bpm then 'target bpm'
		else 'no group, random order'
	end
}
regular expression:      #{grep ? grep : 'none'}
e
usage 'no files to process' if files.empty?
puts
exit if ! askYesNo 'is this correct? start main program'







exit


# main program



while true
	log 'main loop next iteration'
	$db.keys.shuffle.each do |f|
		next if ! f.bpmOk?
		log "doing #{f}"
	end
	sleep 1
end

