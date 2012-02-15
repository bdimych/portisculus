#!/usr/bin/ruby

dbFile = 'bpm-database.txt';


def log(msg)
	t = Time.now
	puts "[#{t.strftime '%H:%M:%S'}.#{sprintf '%03u', t.usec/1000}] #{msg}"
end



if `soundstretch 2>&1` !~ /SoundStretch.*Written by Olli Parviainen/
	raise 'could not find soundstretch'
end



log 'reading db';
db = {}
dbStat = {
	:nonexistent => 0,
	:dirs => 0,
	:files => 0,
	:withoutBpm => 0
}
if ! File.exists? dbFile
	raise "bpm database file #{dbFile} does not exist"
else
	File.open(dbFile).each do |line|
		line.gsub!(/^\s*|\s*$/, '')
		next if line.empty?
		skip = line.slice!(/^\s*-\s*/)
		path, bpm = line.split(/\s*:\s*/)
		next if db[path]
		db[path] = {
			:skip => skip,
			:bpm => bpm
		}
		dbStat[:nonexistent] += 1 if ! File.exists? path
		dbStat[:dirs] += 1 if File.directory? path
		if File.file? path
			dbStat[:files] += 1
			dbStat[:withoutBpm] += 1 if ! bpm
		end
	end
end
log "db loaded: #{dbStat.inspect}"





require 'find'
require 'fileutils'

# first pass: determine bpm only automatically and collecting statistics

log 'first pass'
dbStat = {
	:tried => 0,
	:determined => 0,
	:failed => 0
}
db.keys.sort.each do |dir|
	next if ! File.directory? dir
	log "doing directory #{dir}"
	
	Find.find dir do |f|
		next if ! File.file? f or f !~ /\.mp3$/i
		next if db[f] and db[f][:bpm]
		log "doing file #{f}"
		dbStat[:tried] += 1
		
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
				bpm = $1 if line =~ /^Detected BPM rate (\d+)\.\d\s*$/
			end
		end
		if ! bpm.empty?
			log "bpm determined: #{bpm}"
			dbStat[:determined] += 1
			db[f] ||= {}
			db[f][:bpm] = bpm
		else
			log 'determining failed'
			dbStat[:failed] += 1
		end
	end
end
log "first pass done: #{dbStat.inspect}"

exit






		
		
# second pass

db.keys.sort.each do |dir|
	next if ! File.directory? dir
	log "doing directory #{dir}"
	
	Find.find dir do |f|
		next if ! File.file? f or f !~ /\.mp3$/i
		next if db[f] and db[f][:bpm]
		db[f] ||= {}
		
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
				db[f][:bpm] = $1 if line =~ /^Detected BPM rate (\d+\.\d)\s*$/
			end
		end
		if ! "#{db[f][:bpm]}".empty?
			log "bpm determined: #{db[f][:bpm]}"
		else
			while true
				print 'could not determine bpm, (s)kip once, skip (a)lways, count by (h)ands? '
				x = STDIN.gets.chomp
				case x
					when 's'
						log 'skip once'
					when 'a'
						log 'skip always'
						db[f][:bpm] = 'skip always'
					when 'h'
						log 'by hands'
						trap('INT') {} # let ctrl-c to pass inside
						db[f][:bpm] = `./count-bpm-by-hands.sh`
						trap 'INT', 'DEFAULT'
						log "bpm counted: #{db[f][:bpm]}"
					else next
				end
				break
			end
		end
		
	end
end








log 'writing db'
File.open "#{dbFile}", 'w' do |fh|
	db.keys.sort.each do |path|
		skip = db[path][:skip] ? '- ' : ''
		fh.puts "#{skip}#{path}" + (File.directory?(path) ? '' : ": #{db[path][:bpm]}")
	end
end

log 'the end'

