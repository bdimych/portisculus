if `soundstretch 2>&1` !~ /SoundStretch.*Written by Olli Parviainen/
	raise 'could not find soundstretch'
end



def log msg
	t = Time.now
	puts "[#{t.strftime '%H:%M:%S'}.#{sprintf '%03u', t.usec/1000}] #{msg}"
end

def wrn msg
	log "WARNING: #{msg}"
end





$dbFile = '/home/bdimych/bdimych.txt/bpm-database.txt';

$db = {}

def dbStat
	dbStat = {
		:totalPaths => $db.keys.size,
		
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

def dbSet path, key, value
	if ! $db[path]
		$db[path] = {}
		$db[path][:nonexistent] = true if ! File.exists? path
		$db[path][:dir] = true if File.directory? path
	end
	$db[path][key] = value
	$dbChanged = true
end

class String
	def bpmOk?
		$db[self][:bpm].to_s =~ /^\d+$/ and $db[self][:bpm].to_i > 0
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
		! $db[self][:nonexistent] and ! $db[self][:dir] and ! self.skipped? and ! self.beatless? and ! self.bpmOk?
	end
	def canBeCopied?
		! $db[self][:nonexistent] and ! $db[self][:dir] and ! self.skipped? and (self.bpmOk? or self.beatless?)
	end
end






require 'pathname'
log 'reading db';
if ! File.exists? $dbFile
	raise "bpm database file #$dbFile does not exist"
else
	File.open($dbFile).each do |line|
		line.gsub!(/^\s*|\s*$/, '')
		next if line.empty?
		
		flag = line.slice!(/^\s*([+\-=])\s*/) ? $1 : nil
		path, bpm = line.split(/\s*:(?!\\)\s*/) # (?!\\) is needed for do not split dos paths C:\...
		path.gsub! /^"|"$/, ''
		if path =~ /\\/ and RUBY_PLATFORM =~ /cygwin/
			log "dos path found #{path}"
			log "cygpath result: #{path = %x(cygpath "#{path}").chomp}"
			raise "cygpath failed: #$?" if $? != 0
		end
		path = Pathname.new(path).cleanpath.to_s
		
		dbSet path, :flag, flag
		dbSet path, :bpm, bpm
	end
end
log "db loaded: #{dbStat.inspect}"
$dbChanged = false






def writeDb
	log "going to write db to the #$dbFile"
	if ! $dbChanged
		log "db was not changed: #{dbStat.inspect}, skip writing"
		return
	end
	File.open $dbFile, 'w' do |fh|
		$db.keys.sort.each do |path|
			fh.puts( ($db[path][:flag] ? "#{$db[path][:flag]} " : '') + path + (File.directory?(path) ? '/' : ": #{$db[path][:bpm]}") )
		end
	end
	$dbChanged = false
	log "db written: #{dbStat.inspect}"
end








def readChar prompt, possibleChars = nil
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
	end
end

def askYesNo prompt
	?n != readChar("#{prompt} (Y, n)? ", [?y, ?n])
end



