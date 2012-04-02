#!/usr/bin/ruby

require 'lib.rb'




rangeNeeded = 145..160      # нужный диапазон bpm
rangeAllowed = [0.91, 1.19] # максимальный коефициент на который можно менять bpm (по моим впечатлением больше 1.2 и меньше 0.9 песня уже слух корябит, становится непохожа на саму себя)
bestOnly = false            # только лучшие песни
grep = nil
maxNum = nil
dndo = false




srand





# get options and ask for confirmation

$options = <<e
-r n-n   - needed bpm range
-n n     - maximum number of files to copy
-b       - copy only best songs
-dndo    - do not delete old - exit when no space left on player
remaining argument will be used as regular expression and only matched files will be copied
e
start(true) {
	while ! ARGV.empty?
		case a = ARGV.shift
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
			when /-n(.*)/
				maxNum = $1.empty? ? ARGV.shift : $1
				usage '-n should be a number' if maxNum !~ /^\d+$/
				maxNum = maxNum.to_i
			when '-b'
				bestOnly = true
			when '-dndo'
				dndo = true
			else
				grep = a
		end
	end
}

puts
filesToCopy = $db.keys.sort.select do |path|
	ok = path.canBeCopied?
	ok &&= path.match Regexp.new grep, Regexp::IGNORECASE if grep
	ok &&= path.best? if bestOnly
	ok
end
if grep or bestOnly
	puts "----- regexp and/or -b was specified, #{filesToCopy.count} files matched -----"
	filesToCopy.map {|f| puts f}
	puts "----- regexp and/or -b was specified, #{filesToCopy.count} files matched -----"
	puts
end
puts <<e
target directory:        #$playerDir (#{playerFreeSpace})
needed bpm range:        #{rangeNeeded.min}-#{rangeNeeded.max}
num of files to copy:    #{maxNum ? maxNum : 'all'} of #{filesToCopy.count}
only best songs:         #{bestOnly ? 'yes' : 'no'}
do not delete old:       #{dndo ? 'yes' : ''}
regular expression:      #{grep ? grep : 'none'}
e
usage 'no files to process' if filesToCopy.empty?
puts
exit if ! askYesNo 'is this correct? start main program?'
puts








# main program

log 'preparing for copy loop'

tooLong = {}
unsuitable = {}
added = {}
$deleted = {}
$stat = {
	:sizeDeleted => 0,
	:sizeAdded => 0,
	:startedAt => Time.now
}

$wasCtrlC = nil
trap('INT') {
	puts "\n\n\n"
	log "- - - - - - - - - - - - - - - - - - - - - - - - - !!! Ctrl-C caught !!! - will stop at the nearest appropriate moment\n\n\n"
	$wasCtrlC = true
}
def exitIfWasCtrlC
	if $wasCtrlC
		log 'exit cause of Ctrl-C was caught'
		exit
	end
end

at_exit {
	err = nil
	# http://stackoverflow.com/questions/1144066/ruby-at-exit-exit-status
	if $!.nil? || $!.is_a?(SystemExit) && $!.success?
	else
		if $!.is_a?(SystemExit)
			err = "nonzero SystemExit: #{$!.status}"
		else
			err = 'probably exception - see below this block'
		end
	end

	puts
	puts
	log "------------------------------ at_exit: #{err ? "!!! ERROR !!! #{err}" : 'ok'} ------------------------------"
	puts

	puts "deleted #{$deleted.count}:"
	$deleted.keys.sort.each do |f|
		puts "#{f}: #{sprintf '%.1f', $deleted[f].to_f/1024/1024} Mb"
	end
	puts

	puts "added #{added.count}:"
	added.keys.sort.each do |f|
		puts "#{f}: #{sprintf '%.1f', added[f].to_f/1024/1024} Mb"
	end
	puts

	puts "tooLong #{tooLong.count}:"
	tooLong.keys.sort.each do |f|
		puts "#{f}: #{sec_min_sec tooLong[f]}"
	end
	puts
	
	puts "unsuitable #{unsuitable.count}:"
	unsuitable.keys.sort.each do |f|
		puts "#{f}: #{unsuitable[f].inspect}"
	end
	puts

	if $deleted.empty? and added.empty?
		log 'no files were deleted or added, no need to saveAlreadyInPlayer'
	else
		saveAlreadyInPlayer
	end
	puts

	log "------------------------------ at_exit: #{err ? "!!! ERROR !!! #{err}" : 'ok'} ------------------------------\n\n\n"
}

def rmInPlayer f
	fInPlayer = "#$playerDir/#{$db[f][:inPlayer][:name]}"
	size = File.size fInPlayer
	log "rmInPlayer #{fInPlayer} (#{size/1024} Kb)"
	FileUtils.rm fInPlayer
	$db[f].delete :inPlayer
	$deleted[f] = size
	$stat[:sizeDeleted] += size
end




# clean up songs become skipped and/or out of range

becomeSkipped = []
becomeOutOfRange = []
$db.keys.each do |f|
	if $db[f][:inPlayer]
		if f.skipped?
			becomeSkipped.push f
		elsif $db[f][:inPlayer][:bpm]!='BLS' and !rangeNeeded.include?($db[f][:inPlayer][:bpm].to_i)
			becomeOutOfRange.push f
		end
	end
end
def rmBecomeXXX xxx, arr
	if ! arr.empty?
		wrn "these #{arr.count} files are about to be deleted from player cause of become #{xxx}:"
		puts '---'
		arr.each do |f|
			puts "#{$db[f][:inPlayer][:name]} (#{f})"
		end
		puts '---'
		wrn "these #{arr.count} files are about to be deleted from player cause of become #{xxx}"
		case readChar '(d)elete, do (n)ot delete, (E)xit ? ', [?e, ?d, ?n]
			when ?e
				exit
			when ?d
				arr.each do |f|
					rmInPlayer f
					exitIfWasCtrlC
				end
				log "#{$deleted.count} were deleted"
		end
	end
end
rmBecomeXXX 'skipped', becomeSkipped
rmBecomeXXX 'out of range', becomeOutOfRange





# main loop

log 'copy loop'
filesToCopy.shuffle.each_with_index do |f, i|
	if added.count == maxNum
		log "number of copied files has reached the specified maximum #{maxNum}, exit copy loop"
		break
	end

	log "doing file #{i+1} of #{filesToCopy.count} (added #{added.count}" + (maxNum ? " of #{maxNum}" : '') + "): #{f}"
	
	if $db[f][:inPlayer]
		log 'already in player'
		next
	end
	
	next if ! f.best? and ! checkSongLength f, tooLong
	
	# determine target bpm
	if f.beatless?
		log 'beatless file, no need to check/calculate bpm, will copy unchanged'
	else
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
				unsuitable[f] = [origBpm, allowedMin, allowedMax]
				next
			else
				log "intersection: #{allowedBpmsArr[0]}-#{allowedBpmsArr[-1]}"
				newBpm = allowedBpmsArr.choice
			end
		end
	end
	
	# stretch if needed
	if f.beatless? or newBpm == origBpm
		srcFile = f
	else
		percent = sprintf '%+.1f', newBpm.to_f*100/origBpm - 100
		log "target bpm #{newBpm} (#{percent}%), going to apply soundstretch"
		
		FileUtils.copy_entry f, './tmp.mp3', false, false, true
		
intTrap = trap 'INT', 'DEFAULT'

		log (cmd = %w(lame --decode tmp.mp3 tmp-decoded.wav)).join ' '
		raise 'error decoding mp3' if ! system *cmd
		
		log (cmd = %W(soundstretch tmp-decoded.wav tmp-stretched.wav -tempo=#{percent})).join ' '
		raise 'soundstretch failed' if ! system *cmd
		
		log (cmd = %w(lame --nohist --preset medium tmp-stretched.wav tmp-result.mp3)).join ' '
		raise 'error encoding mp3' if ! system *cmd
		
trap 'INT', intTrap
		
		srcFile = 'tmp-result.mp3'
	end
	
	# name in player
	trgFile = "#$playerDir/0000-#{f.beatless? ? 'BLS' : newBpm}---#{File.basename f}"
	log "target file #{trgFile}"
	raise 'target file already exists' if File.file? trgFile # the probability is small, imho no need to do more code
	
	
	
	# copy file
	noSpace = false
	while true
		log "copying (#{File.size(srcFile)/1024} Kb)"
		begin
			myCopyFile srcFile, trgFile
			log 'SUCCESS!'
			$db[f][:inPlayer] = {
				:name => File.basename(trgFile),
				:bpm => newBpm
			}
			added[f] = File.size srcFile
			$stat[:sizeAdded] += File.size srcFile
			break
		rescue Errno::ENOSPC
			FileUtils.rm trgFile # cleanup _is_required_ else next FileUtils.cp can get troubles with this partially copied file permissions
			wrn 'NO SPACE LEFT'
			if dndo
				log 'stop cause of -dndo'
				noSpace = true
				break
			end
			log 'will try to delete some old file'
			oldDeleted = false
			$db.keys.select do |ff|
				$db[ff][:inPlayer] and ! added.include? ff
			end.sort do |a, b|
				ab = -1; ba = 1;
				# which file should be deleted first/later:
				# best - later
				a.best? and !b.best? and next ba
				!a.best? and b.best? and next ab
				# nonexistent - later (i.e. it was probably added from another machine so on this machine I probably prefer to keep it in player)
				a.exists? and !b.exists? and next ab
				!a.exists? and b.exists? and next ba
				# if file in filesToCopy - later (i.e. now it was not added yet, but later can be, so it looks logically to wait to delete it)
				filesToCopy.include?(a) and !filesToCopy.include?(b) and next ba
				!filesToCopy.include?(a) and filesToCopy.include?(b) and next ab
				# finally by date
				$db[a][:inPlayer][:mtime] ||= File.mtime "#$playerDir/#{$db[a][:inPlayer][:name]}"
				$db[b][:inPlayer][:mtime] ||= File.mtime "#$playerDir/#{$db[b][:inPlayer][:name]}"
				$db[a][:inPlayer][:mtime] <=> $db[b][:inPlayer][:mtime]
			end.each do |ff|
				rmInPlayer ff
				oldDeleted = true
				break
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
               deleted: #{$deleted.count} files / #{$stat[:sizeDeleted]/1024/1024} Mb
               added:   #{added.count} files / #{$stat[:sizeAdded]/1024/1024} Mb
               speed:   #{sprintf '%.1f', added.count/execTime} files / #{sprintf '%.1f', $stat[:sizeAdded]/1024/1024/execTime} Mb per second
               player:  #{$db.values.count {|hash| hash[:inPlayer]}} files, #{playerFreeSpace}
"

	break if noSpace
	
	exitIfWasCtrlC
end

