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

log "first files in the #{$playerDir}:"
puts '---'
system "ls '#$playerDir' | head"
puts '---'
exit if ! askYesNo 'is this a player directory? start ordering?'

readDb
readAlreadyInPlayer






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
	for j in (i+1)..(i+15)
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






# упор€дочить файлы на fat32 это известна€ задача именно дл€ mp3 плееров - google://fat32 file ordering
# иде€ вз€та отсюда http://www.murraymoffatt.com/software-problem-0010.html -> http://www.murraymoffatt.com/sortfolder.zip
# просто переместить все файлы во временный каталог, а потом назад но уже в нужном пор€дке и тогда драйвер файловой системы их так и запишет
#
# (у мен€ плеер ALcom Active WP-400)

log 'applying order to the player directory'

startedAt = Time.now

tmpDir = "#$playerDir/tempDirForOrdering"
log "mkdir #{tmpDir}"
Dir.mkdir tmpDir

log 'copying to the temp dir'
result.each_with_index do |hash, i|
	from = "#$playerDir/#{hash[:name]}"
	to = "#{tmpDir}/#{hash[:name]}"
	printf "#{i+1} of #{result.count}: %-90s -> %s\n", from, to
	File.rename from, to
end
File.rename "#$playerDir/alreadyInPlayer.txt", "#{tmpDir}/alreadyInPlayer.txt"

# один раз было так что после перемещени€ назад в корень пор€док не получилс€
# получилось "закругление": 0012, 0013, 0014, ..., 0763, 0000, 0001, ..., 0011
# т.е. такое впечатление что система возможно что-то там кэширует дл€ usb
# и начала заполн€ть €чейки дл€ файлов те которые последние освободились и ещЄ вис€т в буфере
# € не уверен, но вдруг этот "тычок кэша" поможет
tfdm = "#$playerDir/temp-file-delete-me.txt"
sleep 1
File.open(tfdm, 'w') {|fh| fh.puts tfdm}
sleep 1
File.delete tfdm
sleep 1

log 'copying back to the player root'
result.each_with_index do |hash, i|
	from = "#{tmpDir}/#{hash[:name]}"
	hash[:name].sub!(/^..../, sprintf('%04u', i))
	to = "#$playerDir/#{hash[:name]}"
	printf "#{i+1} of #{result.count}: %-110s -> %s\n", from, to
	File.rename from, to
end

saveAlreadyInPlayer

log "rmdir #{tmpDir}"
File.delete "#{tmpDir}/alreadyInPlayer.txt"
Dir.rmdir tmpDir





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




