#!/usr/bin/ruby

require 'lib.rb'




start true




log 'filling arrays of songs'

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
	for j in (i+1)..(i+5)
		break if j == aip.count
		diff = aip[i][:bpm].to_i - aip[j][:bpm].to_i
		if diff.abs > maxDiff.abs
			maxDiff = diff
			newNextInd = j
		end
	end
	aip[i+1], aip[newNextInd] = aip[newNextInd], aip[i+1]
end

class Array
	def insertEvenly ins
		interval = (self.count.to_f/(ins.count+1)).round
		log "insertEvenly: self.count: #{self.count}, ins.count: #{ins.count}, interval: #{interval}"
		new = []
		for i in 0..(self.count-1)
			new.push self[i]
			if i > 0 and (i+1)%interval == 0 and ! ins.empty?
				new.push ins.shift
			end
		end
		raise 'something went wrong: "ins" array is not empty after inserting' if ! ins.empty?
		new
	end
end

result = aip.insertEvenly(best).insertEvenly(beatless)





# оказалось что при перемещении может возникнуть NOSPACE и получается что половина перемещены а половина нет и приходится вручную перемещать назад и править alreadyInPlayer.txt
# поэтому надо ну путь хотя бы 100К свободных (и не забыть + размер alreadyInPlayer.txt)

log 'check free space'

begin
	FileUtils.cp "#$playerDir/alreadyInPlayer.txt", "#$playerDir/checkFreeSpace.txt"
	File.open "#$playerDir/checkFreeSpace.txt", 'a' do |fh|
		fh.write "123456789\n"*10000
	end
rescue Errno::ENOSPC
	raise "free space on player is too small and moving files may cause problems so WILL STOP NOW! Free some space and retry"
ensure
	File.delete "#$playerDir/checkFreeSpace.txt"
end






log 'applying order'

# упорядочить файлы на fat32 это известная задача именно для mp3 плееров - google://fat32 file ordering
# идея взята отсюда http://www.murraymoffatt.com/software-problem-0010.html -> http://www.murraymoffatt.com/sortfolder.zip
# просто переместить все файлы в нужном порядке в новый каталог и тогда драйвер файловой системы их так и запишет
#
# (у меня плеер ALcom Active WP-400)

startedAt = Time.now

# just increase trailing number /cygdrive/f/portisculus-N
newPd = $playerDir.sub(/\d+$/) {$&.to_i + 1}
log "new directory will be #{newPd}"
Dir.mkdir newPd

log 'moving'
result.each_with_index do |hash, i|
	from = "#$playerDir/#{hash[:name]}"
	hash[:name].sub!(/^..../, sprintf('%04u', i))
	to = "#{newPd}/#{hash[:name]}"
	printf "#{i+1} of #{result.count}: %-110s -> %s\n", from, to
	File.rename from, to
end

oldPd = $playerDir
$playerDir = newPd
saveAlreadyInPlayer

log "deleting old directory #{oldPd}"
File.delete "#{oldPd}/alreadyInPlayer.txt"
Dir.rmdir oldPd






# проверка

log "applying done in #{(Time.now - startedAt).round} seconds, checking fs order"

lsU = %x(ls -U '#$playerDir').split("\n") & result.map{|h| h[:name]}
File.open('tmp-lsU.txt', 'w') {|fh| fh.puts lsU.join "\n"}
File.open('tmp-result.txt', 'w') {|fh| fh.puts result.map{|h| h[:name]}.join "\n"}
diffCmd = %w(diff tmp-lsU.txt tmp-result.txt)
puts diffCmd.join ' '
if ! system *diffCmd
	raise 'lsU != result'
end




log 'files ordered!'




