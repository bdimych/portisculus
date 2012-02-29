#!/usr/bin/ruby


require 'lib.rb'


playerDir = 'test'
range = [150, 180]   # нужный диапазон bpm
maxCoef = 1.2        # максимальный коефициент на который можно менять bpm. По моим впечатлением больше 1.2 песня уже слух корябит - становится непохожа на саму себя
bestOnly = false     # только лучшие песни
groupBy = nil
grep = nil



log 'parsing command line'
while ! ARGV.empty?
	if ARGV.include? '--help'
		log 'help requested'
		puts
		puts <<e
command line options:

  -b           - only best songs
  -gd          - group resulted files by source directories
  -gb          - group by bpm
  -r 150-160   - needed bpm range
  -pd /player/directory

remaining argument will be used as regular expression and only matched files will be copied
e
		exit
	end
	case a = ARGV.shift
		when '-b'
			bestOnly = true
		when '-gd'
			groupBy = :dir
		when '-gb'
			groupBy = :bpm
		when '-r'
			if ARGV.shift =~ /(\d+)-(\d+)/
				range = [$1, $2]
			else
				raise 'range is specified incorrectly - should be "number-number"'
			end
		when '-pd'
			playerDir = ARGV.shift
		else
			grep = a
	end
end
log 'parsing done'

puts
files = $db.keys.sort.select {|path| File.file? path and (! grep or path.match Regexp.new grep, Regexp::IGNORECASE)}
if grep
	puts "#{files.size} files found:"
	puts '-----'
	files.map {|f| puts f}
	puts '-----'
	puts
end
puts <<e
the following parameters will be used:

  player directory:          #{playerDir}
  needed bpm range:          #{range[0]}-#{range[1]}
  only best songs:           #{bestOnly}
  group resulted files by:   #{
		case groupBy
			when :dir then 'source directories'
			when :bpm then 'resulted bpm'
			else 'no group, random order'
		end
	}
  regular expression:        #{grep}
  #{grep ? "regular expression was specified: \"#{grep}\", #{files.size} matched files were found (see above)" : 'no regular expression was specified, all files will be processed'}

e
exit if ! askYesNo 'is this all correct? start main loop'







exit


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

