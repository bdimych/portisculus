#!/usr/bin/ruby

$dbFile = 'bpm-database.txt';


def log(msg)
	t = Time.now
	puts "[#{t.strftime '%H:%M:%S'}.#{sprintf '%03u', t.usec/1000}] #{msg}"
end



if `soundstretch 2>&1` !~ /SoundStretch.*Written by Olli Parviainen/
	raise 'could not find soundstretch'
end



$db = {}
$dbStat = {
	:total => 0,
	:nonexistent => 0,
	:dirs => 0,
	:files => 0,
	:withoutBpm => 0
}
def dbStat
	$dbStat[:total] = $db.keys.size
	$dbStat.inspect
end
$dbChanged = false



log 'reading db';
if ! File.exists? $dbFile
	raise "bpm database file #$dbFile does not exist"
else
	File.open($dbFile).each do |line|
		line.gsub!(/^\s*|\s*$/, '')
		next if line.empty?
		skip = line.slice!(/^\s*-\s*/)
		path, bpm = line.split(/\s*:(?!\\)\s*/) # (?!\\) is needed for do not split dos paths C:\...
		if path =~ /\\/ and RUBY_PLATFORM =~ /cygwin/
			log "dos path found #{path}"
			log "cygpath result: #{path = %x(cygpath '#{path}').chomp}"
			$dbChanged = true
		end
		next if $db[path]
		$db[path] = {
			:skip => skip,
			:bpm => bpm
		}
		$dbStat[:nonexistent] += 1 if ! File.exists? path
		$dbStat[:dirs] += 1 if File.directory? path
		if File.file? path
			$dbStat[:files] += 1
			$dbStat[:withoutBpm] += 1 if bpm !~ /^\d+$/
		end
	end
end
log "db loaded: #{dbStat}"





def writeDb
	log "going to write db to the #$dbFile"
	if ! $dbChanged
		log "db was not changed: #{dbStat}, skip writing"
		return
	end
	File.open $dbFile, 'w' do |fh|
		$db.keys.sort.each do |path|
			skip = $db[path][:skip] ? '- ' : ''
			fh.puts "#{skip}#{path}" + (File.directory?(path) ? '' : ": #{$db[path][:bpm]}")
		end
	end
	$dbChanged = false
	log "db written: #{dbStat}"
end

at_exit {
	alias realPuts puts
	def puts(*args)
		realPuts *args.map {|x| "[at_exit] #{x}"}
	end
	writeDb
	log "the end: #{$!.inspect}"
}





require 'find'
require 'fileutils'

# first pass: determine bpm only automatically and collecting statistics

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

		bpm = false
		cmd = 'soundstretch tmp-decoded.wav -bpm 2>&1'
		log cmd
		IO.popen cmd do |pipe|
			pipe.each_line do |line|
				puts line
				bpm = $1.to_f.round if line =~ /^Detected BPM rate (\d+\.\d)\s*$/
			end
		end

		$db[f] = {}
		$dbStat[:files] += 1
		if bpm
			log "bpm determined: #{bpm}"
			$db[f][:bpm] = bpm
		else
			log 'determining failed'
			$db[f][:bpm] = 'failed'
			$dbStat[:withoutBpm] += 1
		end
		$dbChanged = true

		log "file done: #{dbStat}"
	end
end
writeDb







# prompt for second pass

def readChar(possibleChars)
	begin
		system *%w(stty raw isig -echo)
		until possibleChars.include? c = STDIN.getc do end
	ensure
		system *%w(stty -raw echo)
	end
	puts c.chr
	c
end

puts "\nfirst pass done"
begin
	if $dbStat[:withoutBpm] == 0
		puts 'all files has bpm'
		exit
	else
		print "#{$dbStat[:withoutBpm]} files remains without bpm, count them by hands (y, n)? "
		exit if ?n == readChar([?y, ?n])
	end
ensure
	puts
end




		
		
# second pass

log 'second pass - count by hands'
exit

$db.keys.sort.each do |dir|
	next if ! File.directory? dir
	log "doing directory #{dir}"
	
	Find.find dir do |f|
		next if ! File.file? f or f !~ /\.mp3$/i
		next if $db[f] and $db[f][:bpm]
		$db[f] ||= {}
		
		log "doing file #{f}"
		
		FileUtils.copy_entry f, './tmp.mp3', false, false, true
		
		cmd = %w(lame --decode tmp.mp3 tmp-decoded.wav)
		log cmd.join ' '
		if ! system *cmd
			raise 'error decoding mp3'
		end

		cmd = 'soundstretch tmp-decoded.wav -bpm 2>&1'
		log cmd
		IO.popen cmd do |pipe|
			pipe.each_line do |line|
				puts line
				$db[f][:bpm] = $1 if line =~ /^Detected BPM rate (\d+\.\d)\s*$/
			end
		end
		if ! "#{$db[f][:bpm]}".empty?
			log "bpm determined: #{$db[f][:bpm]}"
		else
			while true
				print 'could not determine bpm, (s)kip once, skip (a)lways, count by (h)ands? '
				x = STDIN.gets.chomp
				case x
					when 's'
						log 'skip once'
					when 'a'
						log 'skip always'
						$db[f][:bpm] = 'skip always'
					when 'h'
						log 'by hands'
						trap('INT') {} # let ctrl-c to pass inside
						$db[f][:bpm] = %x(./count-bpm-by-hands.sh)
						trap 'INT', 'DEFAULT'
						log "bpm counted: #{$db[f][:bpm]}"
					else next
				end
				break
			end
		end
		
	end
end







log 'the end'

