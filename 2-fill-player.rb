#!/usr/bin/ruby

require 'lib.rb'




$playerDir = '/cygdrive/e'
rangeNeeded = 150..180      # нужный диапазон bpm
rangeAllowed = [0.95, 1.15] # максимальный коефициент на который можно менять bpm (по моим впечатлением больше 1.2 и меньше 0.9 песня уже слух корябит, становится непохожа на саму себя)
bestOnly = false            # только лучшие песни
groupBy = nil
grep = nil
maxNum = nil




srand




# parsing command line

log 'parsing command line'

def usage errorMsg = nil
	if errorMsg
		puts
		puts "ERROR! #{errorMsg}"
	end
	puts <<e

possible options:
   -pd /player/directory
   -r N-N   - needed bpm range
   -n N     - maximum number of files to copy
   -b       - copy only best songs
   -gd      - group target files by source directories
   -gb      - group by bpm
   remaining argument will be used as regular expression and only matched files will be copied
e
	exit errorMsg ? 1 : 0
end

def playerFreeSpace
	%x(df #$playerDir).split("\n")[1].split(/ +/)[3] + ' Kb free'
end

usage if ARGV.include? '--help'
while ! ARGV.empty?
	case a = ARGV.shift
		when /-n(.*)/
			maxNum = $1.empty? ? ARGV.shift : $1
			usage '-n should be a number' if maxNum !~ /^\d+$/
			maxNum = maxNum.to_i
		when '-b'
			bestOnly = true
		when '-gd', '-gb'
			if groupBy
				usage '-gd and -gb are mutually exclusive'
			end
			groupBy = a == '-gd' ? :dir : :bpm
		when /-r(.*)/
			val = $1.empty? ? ARGV.shift : $1
			if val =~ /^(\d+)-(\d+)$/
				rangeNeeded = Range.new $1.to_i, $2.to_i
				if rangeNeeded.min == nil
					usage 'first value in range is larger then the last'
				end
			else
				usage 'range is specified incorrectly - should be "number-number"'
			end
		when '-pd'
			$playerDir = ARGV.shift
		else
			grep = a
	end
end
$playerDir = File::expand_path $playerDir
usage "player directory #$playerDir does not exist" if ! File.directory? $playerDir
log 'parsing done'

puts
filesToCopy = $db.keys.sort.select do |path|
	ok = path.canBeCopied?
	ok &&= path.match Regexp.new grep, Regexp::IGNORECASE if grep
	ok &&= path.best? if bestOnly
	ok
end
if grep or bestOnly
	puts "----- regexp and/or -b was specified, #{filesToCopy.size} files matched -----"
	filesToCopy.map {|f| puts f}
	puts "----- regexp and/or -b was specified, #{filesToCopy.size} files matched -----"
	puts
end
puts <<e
player directory:        #$playerDir (#{playerFreeSpace})
needed bpm range:        #{rangeNeeded.min}-#{rangeNeeded.max}
num of files to copy:    #{maxNum ? maxNum : 'all'} of #{filesToCopy.size}
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
exit if ! askYesNo 'is this correct? start main program'
puts








# main program

puts 'STARTING MAIN PROGRAM'
puts




# read/write alreadyInPlayer.txt

$aipTxt = "#$playerDir/alreadyInPlayer.txt"
log "reading #$aipTxt"
knownNamesInPlayer = []
if File.file? $aipTxt
	File.open($aipTxt).each do |line|
		# 1234-160---Song name.mp3 < /orig/path
		# |    |
		# |    bpm in player
		# prefix just for ordering
		if line =~ /^(\d{4}-(\d{3})---.+) < (.+\S)$/
			nameInPlayer = $1
			bpmInPlayer = $2
			origPath = $3
			if $db[origPath] and File.file? "#$playerDir/#{nameInPlayer}"
				$db[origPath][:inPlayer] = {
					:name => nameInPlayer,
					:bpm => bpmInPlayer
				}
				knownNamesInPlayer.push nameInPlayer
			end
		else
			raise "could not parse line in the #$aipTxt: \"#{line}\""
		end
	end
end
log "#{knownNamesInPlayer.size} files already in player"

def saveAlreadyInPlayer
	log "saving #$aipTxt"
	lines = []
	$db.each_pair do |f, hash|
		lines.push "#{hash[:inPlayer][:name]} < #{f}" if hash[:inPlayer]
	end
	File.open $aipTxt, 'w' do |fh|
		lines.sort.each do |l|
			fh.puts l
		end
	end
	log "saved, #{lines.size} lines"
	$stat[:filesInPlayer] = lines.size
end




# zeroing player directory

log 'zeroing player directory'
require 'fileutils'
(Dir.entries($playerDir) - %w[. .. alreadyInPlayer.txt] - knownNamesInPlayer).each do |name|
	log "deleting unknown entry #$playerDir/#{name}"
	FileUtils.rm_rf "#$playerDir/#{name}"
end




# copy loop

log 'copy loop'
unsuitable = []
added = []
$deleted = []
$stat = {
	:sizeDeleted => 0,
	:sizeAdded => 0,
	:startedAt => Time.now
}
def rmInPlayer f
	fInPlayer = "#$playerDir/#{$db[f][:inPlayer][:name]}"
	size = File.size fInPlayer
	log "rmInPlayer #{fInPlayer} (#{size/1024} Kb)"
	FileUtils.rm fInPlayer
	$db[f].delete :inPlayer
	saveAlreadyInPlayer
	$deleted.push f
	$stat[:sizeDeleted] += size
end
filesToCopy.shuffle.each_with_index do |f, i|
	if added.size == maxNum
		log "number of copied files has reached the specified maximum #{maxNum}, exit copy loop"
		break
	end

	log "doing file #{i+1} from #{filesToCopy.size}: #{f}"
	
	# is there f already in player
	if $db[f][:inPlayer]
		log "already in player, bpm in player #{$db[f][:inPlayer][:bpm]}"
		if rangeNeeded.include? $db[f][:inPlayer][:bpm].to_i
			log 'appropriate, no need to copy, go next file'
			next
		end
		log 'out of the needed range, doing further'
	end
	
	# determine target bpm
	origBpm = $db[f][:bpm].to_i
	log "original bpm #{origBpm}"
	if rangeNeeded.include? origBpm
		log 'appropriate, will copy unchanged'
		newBpm = origBpm
	else
		log 'out of the needed range, will calculate new'
		allowedMin = (origBpm * rangeAllowed[0]).to_i
		allowedMax = (origBpm * rangeAllowed[1]).to_i
		log "allowed range: #{allowedMin}-#{allowedMax}"
		allowedBpmsArr = rangeNeeded.to_a & Range.new(allowedMin, allowedMax).to_a
		if allowedBpmsArr.empty?
			wrn 'allowed and needed ranges do not intersect, will list such unsuitable songs at exit'
			unsuitable.push f
			next
		else
			log "allowed and needed intersection: #{allowedBpmsArr[0]}-#{allowedBpmsArr[-1]}"
			newBpm = allowedBpmsArr.choice
		end
	end
	
	# stretch if needed
	if newBpm == origBpm
		srcFile = f
	else
		percent = sprintf '%+.1f', newBpm.to_f*100/origBpm - 100
		log "target bpm #{newBpm} (#{percent}%), going to apply soundstretch"
		
		FileUtils.copy_entry f, './tmp.mp3', false, false, true
		
		log (cmd = %w(lame --decode tmp.mp3 tmp-decoded.wav)).join ' '
		raise 'error decoding mp3' if ! system *cmd
		
		log (cmd = %W(soundstretch tmp-decoded.wav tmp-stretched.wav -tempo=#{percent})).join ' '
		raise 'soundstretch failed' if ! system *cmd
		
		log (cmd = %w(lame --nohist --preset medium tmp-stretched.wav tmp-result.mp3)).join ' '
		raise 'error encoding mp3' if ! system *cmd
		
		srcFile = 'tmp-result.mp3'
	end
	
	# name in player
	trgFile = "#$playerDir/0000-#{newBpm}---#{File.basename f}"
	log "target file #{trgFile}"
	raise 'target file already exists' if File.file? trgFile # the probability is small, imho no need to do more code
	
	
	
	# copy file
	if $db[f][:inPlayer]
		log 'deleting old file'
		rmInPlayer f
	end
	noSpace = false
	while true
		log "copying (#{File.size(srcFile)/1024} Kb)"
		begin
			FileUtils.cp srcFile, trgFile, :verbose => true
			log 'SUCCESS! :)'
			$db[f][:inPlayer] = {
				:name => File.basename(trgFile),
				:bpm => newBpm
			}
			saveAlreadyInPlayer
			added.push f
			$stat[:sizeAdded] += File.size srcFile
			break
		rescue Errno::ENOSPC
			FileUtils.rm trgFile # cleanup _is_required_ else next FileUtils.cp can get troubles with this partially copied file permissions
			wrn 'NO SPACE LEFT, will try to delete some old file'
			oldDeleted = false
			$db.keys.each do |ff|
				if $db[ff][:inPlayer] and ! added.include? ff
					rmInPlayer ff
					oldDeleted = true
					break
				end
			end
			next if oldDeleted
			wrn 'no old files left, can not free space any more, stop copy loop'
			noSpace = true
			break
		end
	end



	execTime = Time.now - $stat[:startedAt]
	log "file done, copy loop statistics:
               time:    #{execTime.round} seconds
               deleted: #{$deleted.size} files / #{$stat[:sizeDeleted]/1024/1024} Mb
               added:   #{added.size} files / #{$stat[:sizeAdded]/1024/1024} Mb
               speed:   #{sprintf '%.1f', added.size/execTime} files / #{sprintf '%.1f', $stat[:sizeAdded]/1024/1024/execTime} Mb per second
               player:  #{$stat[:filesInPlayer]} files, #{playerFreeSpace}
"

	break if noSpace
end

log 'copy loop end'
puts 'deleted:'
puts $deleted.join "\n"
puts 'added:'
puts added.join "\n"




# grouping

