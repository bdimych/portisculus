#!/usr/bin/ruby

require 'lib.rb'




$rangeNeeded = 148..153         # нужный диапазон bpm
rangeCoefAllowed = [0.91, 1.19] # максимальный коэфициент на который можно менять bpm (по моим впечатлением больше 1.2 и меньше 0.9 песня уже слух корябит, становится непохожа на саму себя)
$onlyBest = false               # только лучшие песни
$grep = nil
maxNumOfFilesToAdd = nil
dndo = false




srand





# get options and ask for confirmation

$options = <<eos
-n n - maximum number of files to add
-dndo - do not delete old i.e. exit at once when no space is left on player
eos
start(true, true) {
	while ! ARGV.empty?
		case a = ARGV.shift
			when /-n(.*)/
				maxNumOfFilesToAdd = $1.empty? ? ARGV.shift : $1
				usage '-n should be a number' if maxNumOfFilesToAdd !~ /^\d+$/
				maxNumOfFilesToAdd = maxNumOfFilesToAdd.to_i
			when '-dndo'
				dndo = true
		end
	end
	usage '-dndo and -ob may not be specified together' if dndo and $onlyBest
}

filesToAdd = $db.keys.sort.select do |path|
	path.canBeAdded? and (! filtered? or path.matchToFilter?)
end
puts
if filtered?
	puts "----- regexp and/or -ob was specified, #{filesToAdd.count} files matched -----"
	filesToAdd.map {|f| puts f}
	puts "----- regexp and/or -ob was specified, #{filesToAdd.count} files matched -----"
	puts
end
puts <<e
target directory:        #$playerDir (#{playerFreeSpace})
needed bpm range:        #{rangeStr $rangeNeeded}
num of files to add:     #{maxNumOfFilesToAdd ? maxNumOfFilesToAdd : 'all'} of #{filesToAdd.count}
only best songs:         #{$onlyBest ? 'yes' : 'no'}
do not delete old:       #{dndo ? 'yes' : ''}
regular expression:      #{$grep ? $grep : 'none'}
e
usage 'no files to process' if filesToAdd.empty?
puts
exit if ! askYesNo 'is this correct? start main program?'
puts








# main program

log 'preparing for adding loop'

added = {}
$deleted = {}
unsuitable = {}
tooLong = {}
lameDecodeProblem = {}
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
	# determine is there error
	# http://stackoverflow.com/questions/1144066/ruby-at-exit-exit-status
	err = nil
	if $!.nil? || $!.is_a?(SystemExit) && $!.success?
	else
		if $!.is_a?(SystemExit)
			err = "nonzero SystemExit: #{$!.status}"
		else
			err = "exception: #{$!.inspect}"
		end
	end

	# cosmetic
	atExitLine = (err ? '!' : '-') * 30
	atExitLine = "#{atExitLine} at_exit #{err ? "error!: #{err}" : 'ok'} #{atExitLine}"
	puts
	puts
	log atExitLine
	puts

	# print statistics
	puts "#{$deleted.count} deleted:"
	$deleted.keys.sort.each do |f|
		puts "#{f}: #{sprintf '%.1f', $deleted[f].to_f/1024/1024} Mb"
	end
	puts

	puts "#{added.count} added (#{added.keys.count{|ff| ff =~ /^#$playerDir/}} recodedFromThePlayerDirItself):"
	added.keys.sort.each do |f|
		puts "#{f}: #{sprintf '%.1f', added[f].to_f/1024/1024} Mb"
	end
	puts

	puts "#{tooLong.count} tooLong:"
	tooLong.keys.sort.each do |f|
		puts "#{f}: #{sec_min_sec tooLong[f]}"
	end
	puts
	
	puts "#{unsuitable.count} unsuitable:"
	unsuitable.keys.sort.each do |f|
		puts "#{f}: #{unsuitable[f]}"
	end
	puts

	puts "#{lameDecodeProblem.count} lameDecodeProblem:"
	lameDecodeProblem.keys.sort.each do |f|
		puts "#{f}: #{lameDecodeProblem[f]}"
	end
	puts

	# saveAlreadyInPlayer if needed
	if $deleted.empty? and added.empty?
		log 'no files were deleted or added, no need to saveAlreadyInPlayer'
	else
		saveAlreadyInPlayer
	end
	puts

	# ask to run 3-order
	cmd = %W(./3-order-files-in-player.rb -dbf #$dbFile -prd #{File.dirname $playerDir})
	if filtered?
		cmd.push '-ob' if $onlyBest
		cmd.push '-re', $grep if $grep
	end
	exec *cmd if askYesNo "2-fill finished #{err ? "with error:\nerr: #{err}\n$! is #{$!.inspect}\n$@ is #{$@.inspect}" : 'correctly'}\n\ndo you want to run ['#{cmd.join "' '"}'] ?"
	puts
	
	# cosmetic
	log "#{atExitLine}\n\n"
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
		elsif $db[f][:inPlayer][:bpm]!='BLS' and !$rangeNeeded.include?($db[f][:inPlayer][:bpm].to_i)
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
rmBecomeXXX 'out of range', becomeOutOfRange if ! filtered? # если filtered? то те которые out of range удалять НЕ НАДО - их 3-order сдвинет назад




# если задан фильтр то подготовить пережатие на плеере

if filtered?
	log 'search player for Nonexistent Matched and Out-Of-Range songs'
	$db.keys.each do |f|
		if $db[f][:inPlayer] and f.matchToFilter? and !f.exists? and !f.beatless? and !$rangeNeeded.include?($db[f][:inPlayer][:bpm].to_i)
			path = "#$playerDir/#{$db[f][:inPlayer][:name]}"
			log "NMOOR found #{path}"
			dbSet path, :bpm, $db[f][:inPlayer][:bpm]
			filesToAdd.push path
		end
	end
end





# main loop

log 'adding loop'
filesToAdd.shuffle.each_with_index do |f, i|
	if added.count == maxNumOfFilesToAdd
		log "number of added files has reached the specified maximum #{maxNumOfFilesToAdd}, exit adding loop"
		break
	end

	log "doing file #{i+1} of #{filesToAdd.count} (added #{added.count}" + (maxNumOfFilesToAdd ? " of #{maxNumOfFilesToAdd}" : '') + "): #{f}"
	
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
		if $rangeNeeded.include? origBpm
			log 'appropriate, will copy unchanged'
			newBpm = origBpm
		else
			log 'out of the needed range, will calculate new'
			allowedMin = (origBpm * rangeCoefAllowed[0]).to_i
			allowedMax = (origBpm * rangeCoefAllowed[1]).to_i
			log "allowed range: #{allowedMin}-#{allowedMax}"
			allowedBpmsArr = $rangeNeeded.to_a & Range.new(allowedMin, allowedMax).to_a
			if allowedBpmsArr.empty?
				wrn 'allowed and needed ranges do not intersect, will list such unsuitable songs at exit'
				unsuitable[f] = "[orig #{origBpm} -> allowed #{allowedMin}-#{allowedMax}]"
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
							#
							# как то раз обнаружил на плеере файлы размером всего по несколько килобайт
							# оказалось это lame ошибается но возвращает ноль:
							#
							# bdimych@bdimych-win7 ~/portisculus
							# $ lame --decode tmp.mp3 tmp-decoded.wav ; echo $?
							# input:  tmp.mp3  (16 kHz, 1 channel, MPEG-2 Layer II)
							# output: tmp-decoded.wav  (16 bit, Microsoft WAVE)
							# skipping initial 241 samples (encoder+decoder delay)
							# Frame#     2/4325   160 kbps         hip: bitstream problem, resyncing skipping 1818 bytes...
							# Frame#     3/4325    96 kbps         hip: bitstream problem, resyncing skipping 172184 bytes...
							# Frame#     4/4325   144 kbps         hip: bitstream problem, resyncing skipping 21274 bytes...
							# Frame#     5/4325   128 kbps         hip: bitstream problem, resyncing skipping 541 bytes...
							# Error: sample frequency has changed in MP3 file - not supported
							#
							# 0
							#
							# этот баг есть в гугле
							# http://mp3-encoding.31853.n2.nabble.com/lame-decode-failing-to-abort-on-garbage-files-td34649.html
							# но ещё не исправлен (2012-04-03-03-22-50 версия lame 3.99.5)
							#
							# поэтому вот ещё простейшая проверка на размер
		if 100000 > File.size('tmp-decoded.wav')
			wrn 'tmp-decoded.wav is too small, probably lame failed'
			lameDecodeProblem[f] = File.size('tmp-decoded.wav')
			next
		end
		
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
	raise "target file #{trgFile} already exists" if File.file? trgFile # the probability is small, imho no need to do more code
	
	
	
	# add file to the player
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
				next false if filtered? and ff.matchToFilter? # i.e. if filter(s) was specified then DO NOT DELETE files which match to the filter
				$db[ff][:inPlayer] and ! added.include? ff
			end.sort do |a, b|
				ab = -1; ba = 1;
				# which file should be deleted first/later:
				# best - later
				a.best? and !b.best? and next ba
				!a.best? and b.best? and next ab
				# nonexistent - later (it was probably added from another machine so on this machine I probably prefer to keep it in player)
				a.exists? and !b.exists? and next ab
				!a.exists? and b.exists? and next ba
				# if file in filesToAdd - later (now it was not added yet, but later can be, so it looks logically to wait to delete it)
				filesToAdd.include?(a) and !filesToAdd.include?(b) and next ba
				!filesToAdd.include?(a) and filesToAdd.include?(b) and next ab
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
			wrn 'no old files left, can not free space any more, stop adding loop'
			noSpace = true
			break
		end
		
	end



	execTime = Time.now - $stat[:startedAt]
	log "file done, statistics:
               time:    #{execTime.round} seconds
               deleted: #{$deleted.count} files / #{$stat[:sizeDeleted]/1024/1024} Mb
               added:   #{added.count} files / #{$stat[:sizeAdded]/1024/1024} Mb (#{added.keys.count{|ff| ff =~ /^#$playerDir/}} recodedFromThePlayerDirItself)
               speed:   #{sprintf '%.1f', added.count/execTime} files / #{sprintf '%.1f', $stat[:sizeAdded]/1024/1024/execTime} Mb per second
               player:  #{$db.values.count {|hash| hash[:inPlayer]}} files, #{playerFreeSpace}
"

	break if noSpace
	
	exitIfWasCtrlC
end

