#!/usr/bin/ruby

$dbFile = '/home/bdimych/bdimych.txt/bpm-database.txt';


def log msg
	t = Time.now
	puts "[#{t.strftime '%H:%M:%S'}.#{sprintf '%03u', t.usec/1000}] #{msg}"
end



if `soundstretch 2>&1` !~ /SoundStretch.*Written by Olli Parviainen/
	raise 'could not find soundstretch'
end




$db = {}

def dbStat
	dbStat = {
		:total => $db.keys.size,
		:nonexistent => 0,
		:dirs => 0,
		:files => 0,
		:skipped => 0,
		:beatless => 0,
		:withoutBpm => 0
	}
	$db.each do |path, hash|
		if hash[:nonexistent]
			dbStat[:nonexistent] += 1
		elsif hash[:dir]
			dbStat[:dirs] += 1
		else
			dbStat[:files] += 1
		end
		if path.skipped?
			dbStat[:skipped] += 1
		elsif path.beatless?
			dbStat[:beatless] += 1
		elsif path.withoutBpm?
			dbStat[:withoutBpm] += 1
		end
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
	def skipped?
		$db[self][:flag] == '-'
	end
	def beatless?
		$db[self][:flag] == '='
	end
	def withoutBpm?
		! $db[self][:nonexistent] and ! $db[self][:dir] and ! self.skipped? and ! self.beatless? and ! self.bpmOk?
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

at_exit {
	alias realPuts puts
	def puts *args
		realPuts *args.map {|x| "[at_exit] #{x}"}
	end
	writeDb
	log "the end: #{$!.inspect}"
}





require 'find'
require 'fileutils'

# first pass: try to determine bpm automatically

log 'first pass'
$db.keys.sort.each do |dir|
	next if ! File.directory? dir
	log "doing directory #{dir}"
	
	Find.find dir do |f|
		next if ! File.file? f or f !~ /\.mp3$/i
		log "doing file #{f}"
		if $db[f]
			log 'file is already in database'
			next
		end
		
		FileUtils.copy_entry f, './tmp.mp3', false, false, true
		
		cmd = %w(lame --decode tmp.mp3 tmp-decoded.wav)
		log cmd.join ' '
		if ! system *cmd
			raise 'error decoding mp3'
		end

		bpm = ''
		cmd = 'soundstretch tmp-decoded.wav -bpm 2>&1'
		log cmd
		IO.popen cmd do |pipe|
			pipe.each_line do |line|
				puts line
				bpm = $1.to_f.round if line =~ /^Detected BPM rate (\d+\.\d)\s*$/
			end
		end

		dbSet f, :bpm, bpm
		log "file done: bpm result: \"#{bpm}\", dbStat: #{dbStat.inspect}"
	end
end
writeDb







# prompt for second pass

def readChar prompt, possibleChars = nil
	sttySettingsBck = %x(stty -g).chomp
	begin
		system *%w(stty raw isig opost -echo)
		while true
			print prompt
			c = STDIN.getc
			puts c == 27 ? '' : c.chr # 27 - escape makes terminal doing unwanted things
			return c if ! possibleChars or possibleChars.include? c
		end
	ensure
		system 'stty', sttySettingsBck
	end
end

puts "\nfirst pass done"
pass2 = [0, (dbStat)[:withoutBpm]]
begin
	if pass2[1] == 0
		puts 'all existent nonskipped files has bpm'
		exit
	else
		while true
			case readChar "#{pass2[1]} files remains without bpm, count them by hands (y, n, (l)ist)? ", [?y, ?n, ?l]
				when ?y
					break
				when ?n
					exit
				when ?l
					$db.keys.sort.each do |f|
						puts f if f.withoutBpm?
					end
					puts
			end
		end
	end
ensure
	puts
end






# second pass - count by hands

log 'second pass - count by hands'

$db.keys.sort.each do |f|
	next if ! f.withoutBpm?

	pass2[0] += 1
	progress = "Second pass: #{pass2[0]} from #{pass2[1]}"
	puts
	puts ".#{'-' * (f.length+8+6)}."
	puts "|    #{progress}#{' ' * (f.length+4+6-progress.length)}|"
	puts "|    File: #{f}    |"
	puts "'#{'-' * (f.length+8+6)}'"

	FileUtils.copy_entry f, './tmp.mp3', false, false, true
	
	wasCtrlC = false
	trap('INT') {wasCtrlC = true} # let ctrl-c to pass inside
	ENV['BYHANDS'] = f
	bpm = %x(./count-bpm-by-hands.sh).chomp
	raise Interrupt if wasCtrlC
	trap 'INT', 'DEFAULT'
	
	puts
	log "by hands result: \"#{bpm}\""
	msg = ''
	case bpm
		when /^\d+$/
			dbSet f, :bpm, bpm
		when 'next'
			next
		when 'skip'
			puts
			puts "file #{f}"
			dbSet f, :flag, '-' if ?y == readChar("save as skipped (y, n)? ", [?y, ?n])
			msg = 'skipped'
		when 'beatless'
			puts
			puts "file #{f}"
			dbSet f, :flag, '=' if ?y == readChar("save as beatless (y, n)? ", [?y, ?n])
			msg = 'beatless'
		else
			raise 'unknown byhands result'
	end
	puts
	writeDb
	puts
	puts msg
	readChar 'press any key to continue'
end







log 'the end'

