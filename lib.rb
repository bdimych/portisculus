require 'pathname'
require 'fileutils'
require 'mp3info'




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







def lsHeadTail dir
	ls = Dir.entries(dir).select{|f| f != '.' and f != '..'}.sort
	puts "[#{dir}:\ntotal #{ls.count}:"
	if ls.empty?
		puts 'the directory is empty'
	else
		if ls.count <= 10
			ls.each {|f| puts "  #{f}"}
		else
			for i in 0..ls.count-1
				puts "  #{ls[i]}" if i < 5 or i > ls.count-6
				puts '  ...' if i == 5
			end
		end
	end
	puts ']'
end

def ARGV.getDbFile
	i = self.index '-dbf'
	usage '-dbf must be specified' if ! i
	
	dbf = Pathname.new(self.slice!(i, 2)[1]).cleanpath.to_s
	usage "-dbf \"#{dbf}\" does not exist" if ! File.file? dbf
	usage "empty file -dbf \"#{dbf}\"" if 0 == File.size(dbf)

	$dbFile = dbf
	log "database file #$dbFile"
end

def ARGV.getPlayerRootDir
	i = self.index '-prd'
	usage '-prd must be specified' if ! i
	
	prd = Pathname.new(self.slice!(i, 2)[1]).cleanpath.to_s
	usage "-prd \"#{prd}\" does not exist" if ! File.directory? prd
	log "player root directory:"
	lsHeadTail prd
	prd
end

def ARGV.getFilterOptions
	newArgv = []
	while ! self.empty?
		case a = self.shift
			when '-re'
				$grep = self.shift
				log "filter option: -re #$grep"
			when /-r(.*)/
				r = $1.empty? ? self.shift : $1
				if r =~ /^(\d+)-(\d+)$/
					$rangeComLine = Range.new $1.to_i, $2.to_i
					if $rangeComLine.min == nil
						usage 'first value in range is larger then the last'
					end
					log "filter option: -r #{rangeStr $rangeComLine}"
				else
					usage 'range is specified incorrectly - should be "number-number"'
				end
			when '-ob'
				$onlyBest = true
				log "filter option: -ob"
			else
				newArgv.push a
		end
	end
	self.replace newArgv
end

def determinePlayerDir prd
	Dir.entries(prd).each do |d|
		if File.directory? "#{prd}/#{d}" and d =~ /^portisculus-\d+$/
			$playerDir = "#{prd}/#{d}"
			log "portisculus directory found:"
			lsHeadTail $playerDir
			exit if ! askYesNo 'is this directory correct?'
		end
	end
	if ! $playerDir
		$playerDir = "#{prd}/portisculus-1"
		exit if ! askYesNo "there is no portisculus directory in player root so going to create \"#$playerDir\", proceed?"
		log "mkdir #$playerDir"
		Dir.mkdir $playerDir
	end
end

def usage errorMsg = nil
	if errorMsg
		puts
		puts "ERROR! #{errorMsg}"
	end
	puts "\noptions:\n   #{$options.split("\n").join("\n   ")}\n"
	exit errorMsg ? 1 : 0
end

def start readInPlayer = false, optionsForFilter = false
	$options = "-dbf /bpm/database/file.txt (required)\n#$options"
	$options = "-prd /player/root/directory (required)\n#$options" if readInPlayer
	$options += <<eos if optionsForFilter
-r n-n - needed bpm range
-ob - add only best songs
-re regexp - add only matched files
eos
	usage if ARGV.include? '--help'

	log "#{File.basename $0} started"
	
	if optionsForFilter
		ARGV.getFilterOptions
		if filtered?
			msg = []
			msg.push 'only best' if $onlyBest
			msg.push "regexp: #$grep" if $grep
			msg.push "bpm range: #{rangeStr $rangeNeeded} -> #{rangeStr $rangeComLine}" if $rangeComLine
			msg = "filtered mode: #{msg.join ', '}"
			log '*' * (msg.length+12)
			log "*#{' ' * (msg.length+10)}*"
			log "*     #{msg}     *"
			log "*#{' ' * (msg.length+10)}*"
			log '*' * (msg.length+12)
		end
		$rangeNeeded = $rangeComLine if $rangeComLine
	end
	ARGV.getDbFile
	prd = ARGV.getPlayerRootDir if readInPlayer

	yield if block_given?
	
	determinePlayerDir prd if readInPlayer
	readDb
	readAlreadyInPlayer if readInPlayer
end

def filtered?
	$grep or $onlyBest
end

def rangeStr r
	"#{r.min}-#{r.max}" if r
end

class String
	def matchToFilter?
		return false if $onlyBest and ! self.best?
		return false if $grep and ! self.match Regexp.new $grep, Regexp::IGNORECASE
		return true
	end
end











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
		:canBeAdded => 0
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
		dbStat[:canBeAdded] += 1 if path.canBeAdded?
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
	def canBeAdded?
		self.exists? and !self.dir? and !self.skipped? and (self.bpmOk? or self.beatless?)
	end
end






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
			fh.puts sprintf('%-2s', x[:flag]) + path + (x[:dir] || x[:trailingSlash] ? '/' : ": #{(path.beatless? or path.skipped?) ? '' : x[:bpm]}")
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

def readAlreadyInPlayer
	aipTxt = "#$playerDir/alreadyInPlayer.txt"
	log "reading #{aipTxt}"
	
	pdEntries = Dir.entries $playerDir
	
	knownNamesInPlayer = []
	recodedFromThePlayerDirItself = []
	notInDb = {}
	if pdEntries.include? 'alreadyInPlayer.txt'
		File.open(aipTxt).each do |line|
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
					if origPath == 'recodedFromThePlayerDirItself'
						recodedFromThePlayerDirItself.push nameInPlayer if pdEntries.include? nameInPlayer
					else
						notInDb[nameInPlayer] = origPath
					end
				end
			else
				raise "could not parse line in the #{aipTxt}: \"#{line}\""
			end
		end
	end
	
	log "#{knownNamesInPlayer.count} known files in player, checking other files"

	if ! recodedFromThePlayerDirItself.empty?
		log 'deleting recodedFromThePlayerDirItself'
		IO.popen 'xargs -0 rm -rv', 'w' do |pipe|
			pipe.print recodedFromThePlayerDirItself.map{|nameInPlayer| "#$playerDir/#{nameInPlayer}"}.join "\0"
		end
		raise 'error rm recodedFromThePlayerDirItself' if $? != 0
	end
	
	if ! notInDb.empty?
		wrn "these #{notInDb.count} files are present in the alreadyInPlayer.txt but absent in the database:"
		puts '---'
		notInDb.each do |nameInPlayer, origPath|
			puts "#{nameInPlayer} (#{origPath})"
		end
		puts '---'
		wrn "these #{notInDb.count} files are present in the alreadyInPlayer.txt but absent in the database"
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
	
	unknown = (pdEntries - %w[. .. alreadyInPlayer.txt tempDirForOrdering] - knownNamesInPlayer - recodedFromThePlayerDirItself - notInDb.keys).map{|name| "#$playerDir/#{name}"}
	if ! unknown.empty?
		wrn "these #{unknown.count} files are not mentioned in the alreadyInPlayer.txt:"
		puts '---'
		IO.popen 'xargs -0 ls -ld --group-directories-first --color --file-type --time-style=long-iso', 'w' do |pipe|
			pipe.print unknown.join "\0"
		end
		puts '---'
		wrn "these #{unknown.count} files are not mentioned in the alreadyInPlayer.txt"
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
	aipTxt = "#$playerDir/alreadyInPlayer.txt"
	log "saving #{aipTxt}"
	lines = []
	$db.each_pair do |f, hash|
		lines.push "#{hash[:inPlayer][:name]} < #{f =~ /^#$playerDir/ ? 'recodedFromThePlayerDirItself' : f}" if hash[:inPlayer]
	end
	File.open aipTxt, 'w' do |fh|
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
	sttySettingsBck = %x(stty -g).chomp if STDIN.tty?
	begin
		system *%w(stty raw isig opost -echo) if STDIN.tty?
		while true
			print prompt
			c = STDIN.getc
			c = possibleChars[0] if possibleChars and c == 13 # Enter means default char
			puts c == 27 ? '' : c.chr # 27 - escape makes terminal doing unwanted things
			return c if ! possibleChars or possibleChars.include? c
		end
	ensure
		system 'stty', sttySettingsBck if STDIN.tty?
		trap 'INT', intTrap
	end
end

def askYesNo prompt
	?n != readChar("#{prompt} (Y, n) ", [?y, ?n])
end





def sec_min_sec sec
	"#{sec} sec (#{sec/60} min #{sec%60} sec)"
end

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
# 2. to ignore INT in the child so that the main could wait and exit at the proper moment (e.g. in 2-fill in adding loop it is when one file is done)
	if ! fork
		trap 'INT', 'IGNORE'
		exec *args
	end
	while ! Process.wait -1, Process::WNOHANG
		sleep 0.1
	end
	$? == 0 ? true : nil
end


