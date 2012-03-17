STDOUT.sync = true

def log msg
	t = Time.now
	puts "[#{t.strftime '%H:%M:%S'}.#{sprintf '%03u', t.usec/1000}] #{msg}"
end

def wrn msg
	log "WARNING: #{msg}"
end





if %x(soundstretch 2>&1) !~ /SoundStretch.*Written by Olli Parviainen/
	raise 'could not run soundstretch'
end

raise 'could not run mplayer' if ! system('mplayer >/dev/null')





$db = {}

def dbStat
	dbStat = {
		:totalPaths => $db.keys.count,
		
		:nonexistent => 0,
		:dirs => 0,
		:files => 0,
		
		:best => 0,
		:beatless => 0,
		:skipped => 0,
		
		:withoutBpm => 0,
		:canBeCopied => 0
	}
	$db.each do |path, hash|
		if hash[:nonexistent]
			dbStat[:nonexistent] += 1
		elsif hash[:dir]
			dbStat[:dirs] += 1
		else
			dbStat[:files] += 1
		end
		
		dbStat[:best] += 1 if path.best?
		dbStat[:beatless] += 1 if path.beatless?
		dbStat[:skipped] += 1 if path.skipped?
		
		dbStat[:withoutBpm] += 1 if path.withoutBpm?
		dbStat[:canBeCopied] += 1 if path.canBeCopied?
	end
	dbStat
end

def dbAdd path
	if ! $db[path]
		$db[path] = {}
		$db[path][:nonexistent] = true if ! File.exists? path
		$db[path][:dir] = true if File.directory? path
	end
end

def dbSet path, key, value
	dbAdd path
	$db[path][key] = value
	$dbChanged = true
end

class String
	def bpmOk?
		$db[self][:bpm].to_s =~ /^\d+$/ and $db[self][:bpm].to_i > 0
	end
	def exists?
		! $db[self][:nonexistent]
	end
	def dir?
		$db[self][:dir]
	end
	
	def best?
		$db[self][:flag] == '+'
	end
	def beatless?
		$db[self][:flag] == '='
	end
	def skipped?
		$db[self][:flag] == '-'
	end
	
	def withoutBpm?
		self.exists? and !self.dir? and !self.skipped? and !self.beatless? and !self.bpmOk?
	end
	def canBeCopied?
		self.exists? and !self.dir? and !self.skipped? and (self.bpmOk? or self.beatless?)
	end
end






require 'pathname'
def readDb
	log 'reading db';
	File.open($dbFile).each do |line|
		line.gsub!(/^\s*|\s*$/, '')
		next if line.empty?
		
		flag = line.slice!(/^\s*([+\-=])\s*/) ? $1 : nil
		trailingSlash = line.slice! /\/$/ # in order to correctly writeDb directory paths form another computer and nonexistent on this one
		path, bpm = line.split(/\s*:(?!\\)\s*/) # negative lookahead (?!\\) is needed for do not split dos paths C:\...
		path.gsub! /^"|"$/, '' # e.g. in Total Commander Ctrl-Shift-Enter or in Far Alt-Shift-Insert allows to copy full path doublequoted
		if path =~ /\\/ and RUBY_PLATFORM =~ /cygwin/
			log "dos path found #{path}"
			log "cygpath result: #{path = %x(cygpath "#{path}").chomp}"
			raise "cygpath failed: #$?" if $? != 0
		end
		path = Pathname.new(path).cleanpath.to_s
		
		dbSet path, :flag, flag
		dbSet path, :bpm, bpm
		dbSet path, :trailingSlash, trailingSlash if trailingSlash
		
		log $db.count if $db.count % 1000 == 0
	end
	log "db loaded: #{dbStat.inspect}"
	$dbChanged = false
end

def writeDb
	log 'going to write db'
	if ! $dbChanged
		log "skip writing, db was not changed: #{dbStat.inspect}"
		return
	end
	File.open $dbFile, 'w' do |fh|
		cnt = 0
		$db.keys.sort.each do |path|
			x = $db[path]
			fh.puts sprintf('%-2s', x[:flag]) + path + (x[:dir] || x[:trailingSlash] ? '/' : ": #{x[:bpm]}")
			log cnt if ( (cnt += 1) % 1000 == 0 )
		end
	end
	$dbChanged = false
	log "db written: #{dbStat.inspect}"
end







def playerFreeSpace
=begin
cygwin's df output:
bdimych@bdimych-win7 ~/portisculus
$ df /cygdrive/e
Filesystem     1K-blocks  Used Available Use% Mounted on
E:                 95232 50050     45182  53% /cygdrive/e
=end
	tmp = %x(df #$playerDir).split("\n")[1].split(/ +/)
	return sprintf '%.1f Mb used, %.1f Mb free', tmp[2].to_f/1024, tmp[3].to_f/1024
end

require 'fileutils'
def readAlreadyInPlayer
	$aipTxt = "#$playerDir/alreadyInPlayer.txt"
	log "reading #$aipTxt"
	
	pdEntries = Dir.entries $playerDir
	
	knownNamesInPlayer = []
	notInDb = {}
	if pdEntries.include? 'alreadyInPlayer.txt'
		File.open($aipTxt).each do |line|
			# 1234-160---Song name.mp3 < /orig/path
			# |    |
			# |    bpm in player
			# prefix just for ordering
			if line =~ /^(\d{4}-(\d{3}|BLS)---.+) < (.+\S)$/
				nameInPlayer = $1
				bpmInPlayer = $2
				origPath = $3
				if $db[origPath] and pdEntries.include? nameInPlayer
					$db[origPath][:inPlayer] = {
						:name => nameInPlayer,
						:bpm => bpmInPlayer
					}
					knownNamesInPlayer.push nameInPlayer
				elsif !$db[origPath]
					notInDb[nameInPlayer] = origPath
				end
			else
				raise "could not parse line in the #$aipTxt: \"#{line}\""
			end
		end
	end
	
	log "#{knownNamesInPlayer.count} known files in player, checking other files"
	
	if ! notInDb.empty?
		wrn 'these files are present in the alreadyInPlayer.txt but absent in the database:'
		puts '---'
		notInDb.each do |nameInPlayer, origPath|
			puts "#{nameInPlayer} (#{origPath})"
		end
		puts '---'
		wrn 'these files are present in the alreadyInPlayer.txt but absent in the database'
		case readChar '(d)elete, do (n)ot delete, (E)xit ? ', [?e, ?d, ?n]
			when ?e
				exit
			when ?d
				IO.popen 'xargs -0 rm -rv', 'w' do |pipe|
					pipe.print notInDb.keys.map{|nameInPlayer| "#$playerDir/#{nameInPlayer}"}.join "\0"
				end
				raise 'error rm notInDb' if $? != 0
		end
	end
	
	unknown = (pdEntries - %w[. .. alreadyInPlayer.txt] - knownNamesInPlayer - notInDb.keys).map{|name| "#$playerDir/#{name}"}
	if ! unknown.empty?
		wrn 'these files are not mentioned in the alreadyInPlayer.txt:'
		puts '---'
		IO.popen 'xargs -0 ls -ld --group-directories-first --color --file-type --time-style=long-iso', 'w' do |pipe|
			pipe.print unknown.join "\0"
		end
		puts '---'
		wrn 'these files are not mentioned in the alreadyInPlayer.txt'
		case readChar '(d)elete, do (n)ot delete, (E)xit ? ', [?e, ?d, ?n]
			when ?e
				exit
			when ?d
				IO.popen 'xargs -0 rm -rv', 'w' do |pipe|
					pipe.print unknown.join "\0"
				end
				raise 'error rm unknown' if $? != 0
		end
	end
	
	log 'readAlreadyInPlayer done'
end

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
	log "saved, #{lines.count} lines"
end







def myCopyFile from, to
	log "myCopyFile \"#{from}\" \"#{to}\""
	bytesCopied = 0
	File.open from, 'rb' do |fromFh|
		File.open to, 'wb' do |toFh|
			toFh.sync = true
			while buf = fromFh.read(1024*1024)
				log "#{bytesCopied += toFh.write buf} bytes copied"
			end
		end
	end
	log 'myCopyFile done'
end







def readChar prompt, possibleChars = nil
	intTrap = trap 'INT', 'DEFAULT'
	sttySettingsBck = %x(stty -g).chomp
	begin
		system *%w(stty raw isig opost -echo)
		while true
			print prompt
			c = STDIN.getc
			c = possibleChars[0] if possibleChars and c == 13 # Enter means default char
			puts c == 27 ? '' : c.chr # 27 - escape makes terminal doing unwanted things
			return c if ! possibleChars or possibleChars.include? c
		end
	ensure
		system 'stty', sttySettingsBck
		trap 'INT', intTrap
	end
end

def askYesNo prompt
	?n != readChar("#{prompt} (Y, n) ", [?y, ?n])
end





def sec_min_sec sec
	"#{sec} sec (#{sec/60} min #{sec%60} sec)"
end

require 'mp3info'
def checkSongLength file, tooLongHash
	log 'checkSongLength'
	msg = sec_min_sec(l = Mp3Info.new(file).length.round)
	if l > 7*60
		tooLongHash[file] = l
		wrn "#{msg} - TOO LONG!, should be skipped, tooLongHash appended"
		return nil
	end
	log "#{msg} - ok"
	return true
end




def mySystem *args
# two purposes:
# 1. to allow trap INT in the main process when the child is running (ruby's own "system" does not allow this (ruby 1.8.7 cygwin))
# 2. to ignore INT in the child so that the main could wait and exit at the proper moment (e.g. in 2-fill in copy loop it is when one file is done)
	if ! fork
		trap 'INT', 'IGNORE'
		exec *args
	end
	while ! Process.wait -1, Process::WNOHANG
		sleep 0.1
	end
	$? == 0 ? true : nil
end

