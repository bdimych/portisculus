#!/usr/bin/ruby

require_relative 'lib.rb'




start true, true




log 'filling lists of songs'

srand

$lists = {
	:filtered => {
		:best => [],
		:beatless => [],
		:common => [],
		:result => []
	},
	:rest => {
		:best => [],
		:beatless => [],
		:common => [],
		:result => []
	}
}

$db.keys.shuffle.each do |f|
	if hash = $db[f][:inPlayer]
		target = (filtered? and f.matchToFilter? and (!$rangeNeeded or $rangeNeeded.include?(hash[:bpm].to_i))) ? $lists[:filtered] : $lists[:rest]
		if f.best?
			target = target[:best]
		elsif f.beatless?
			target = target[:beatless]
		else
			target = target[:common]
		end
		target.push hash
	end
end






log 'calculating new order'

def insertEvenly key, base, ins, res
	log "insertEvenly #{key}, #{base}, #{ins}, #{res}"
	base = $lists[key][base]
	ins = $lists[key][ins]
	res = $lists[key][res]
	interval = (base.count.to_f/(ins.count+1)).round
	log "insertEvenly begin: base.count: #{base.count}, ins.count: #{ins.count}, interval: #{interval}, res.count: #{res.count}"
	new = []
	for i in 0..(base.count-1)
		new.push base[i]
		if i > 0 and (i+1)%interval == 0 and ! ins.empty?
			new.push ins.shift
		end
	end
	res.replace(new + ins)
	log "insertEvenly end: base.count: #{base.count}, ins.count: #{ins.count}, interval: #{interval}, res.count: #{res.count}"
end

def distributeByBpm key, subkey
	log "distributeByBpm #{key}, #{subkey}"
	arr = $lists[key][subkey]
	for i in 0..(arr.count-3)
		newNextInd = i + 1
		maxDiff = 0
		for j in (i+1)..(i+5)
			break if j == arr.count
			diff = arr[i][:bpm].to_i - arr[j][:bpm].to_i
			if diff.abs > maxDiff.abs
				maxDiff = diff
				newNextInd = j
			end
		end
		arr[i+1], arr[newNextInd] = arr[newNextInd], arr[i+1]
	end
end

[:filtered, :rest].each do |key|
	insertEvenly key, :common, :best, :result
	distributeByBpm key, :result
	insertEvenly key, :result, :beatless, :result
end
result = $lists[:filtered][:result] + $lists[:rest][:result]





# оказалось что при перемещении может возникнуть NOSPACE и получается что половина перемещены а половина нет и приходится вручную перемещать назад и править alreadyInPlayer.txt
# поэтому надо ну путь хотя бы 100К свободных (и не забыть + размер alreadyInPlayer.txt)

log 'check free space'

begin
	FileUtils.cp "#$playerDir/alreadyInPlayer.txt", "#$playerDir/checkFreeSpace.txt"
	File.open "#$playerDir/checkFreeSpace.txt", 'a' do |fh|
		fh.write "123456789\n"*10000
	end
rescue Errno::ENOSPC
	raise 'free space on player is too small and moving files may cause problems so WILL STOP NOW! Free some space and retry'
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




