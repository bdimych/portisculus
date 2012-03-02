#!/usr/bin/ruby


require 'lib.rb'




playerDir = '/cygdrive/e'
range = 150..180     # нужный диапазон bpm
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
				range = $1.to_i .. $2.to_i
				if range.min == nil
					usage 'first value in range is larger then the last'
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
filesToCopy = $db.keys.sort.select do |path|
	ok = path.canBeCopied?
	ok &&= path.match Regexp.new grep, Regexp::IGNORECASE if grep
	ok &&= path.best? if bestOnly
	ok
end
if grep or bestOnly
	puts "#{filesToCopy.size} files found:"
	puts '-----'
	filesToCopy.map {|f| puts f}
	puts '-----'
	puts "#{filesToCopy.size} files found"
	puts
end
puts <<e
player directory:        #{playerDir}
needed bpm range:        #{range.min}-#{range.max}
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
usage 'no files to process' if filesToCopy.empty?
puts
#exit if ! askYesNo 'is this correct? start main program'
puts
puts 'STARTING MAIN PROGRAM'
puts



exit



# main program


# reading alreadyInPlayer.txt

log 'reading alreadyInPlayer.txt'
knownNamesInPlayer = []
if File.file? "#{playerDir}/alreadyInPlayer.txt"
	File.open("#{playerDir}/alreadyInPlayer.txt").each do |line|
		# /orig/path > 1234-160---Song name.mp3
		#              ^    ^
		#     prefix for    bpm
		#     ordering
		if line =~ /^(\S.+) > (\d{4}-(\d{3})---.+\S)$/
			origPath = $1
			nameInPlayer = $2
			bpmInPlayer = $3
			if $db[origPath] and File.file? "#{playerDir}/#{nameInPlayer}"
				$db[origPath][:inPlayer] = {
					:name => nameInPlayer,
					:bpm => bpmInPlayer
				}
				knownNamesInPlayer.push nameInPlayer
			end
		else
			raise "could not parse line in the alreadyInPlayer.txt: \"#{line}\""
		end
	end
end




# zeroing player directory

log 'zeroing player directory'
require 'fileutils'
(Dir.entries(playerDir) - %w[. .. alreadyInPlayer.txt] - knownNamesInPlayer).each do |name|
	log "deleting unknown entry #{playerDir}/#{name}"
	FileUtils.rm_rf "#{playerDir}/#{name}"
end



# copy loop

log 'copy loop'
filesToCopy.shuffle.each_with_index do |f, i|
	log "doing file #{i+1} from #{filesToCopy.size}: #{f}"
#	if $db[f][:inPlayer] and 
#	end
end




