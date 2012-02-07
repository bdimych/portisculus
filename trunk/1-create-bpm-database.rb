#!/usr/bin/ruby

dbFile = 'bpm-database.txt';


def log(msg)
	t = Time.now
	puts "[#{t.strftime('%H:%M:%S')}.#{sprintf '%03u', t.usec/1000}] #{msg}"
end



log 'reading db';
db = {}
dbStat = {:nonexistent => 0, :dirs => 0, :files => 0, :withoutBpm => 0}
if ! File.exists? dbFile
	log "bpm database file #{dbFile} does not exist"
	exit
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
log "db loaded: paths total: #{db.keys.size}, nonexistent: #{dbStat[:nonexistent]}, directories: #{dbStat[:dirs]}, files total: #{dbStat[:files]}, without bpm: #{dbStat[:withoutBpm]}"




require 'find'
require 'fileutils'
db.keys.sort.each do |dir|
	next if ! File.directory? dir
	log "doing directory #{dir}"
	Find.find dir do |f|
		next if ! File.file? f or f !~ /\.mp3$/i or (db[f] and db[f][:bpm])
		log "doing file #{f}"
		FileUtils.copy_entry(f, './tmp.mp3', false, false, true)
		
		cmd = %w(lame --decode tmp.mp3 tmp-decoded.wav)
		log cmd.join ' '
		if ! system *cmd
			raise 'error decoding mp3'
		end

		cmd = 'soundstretch tmp-decoded.wav -bpm'
		log cmd
		IO.popen cmd do |pipe|
			pipe.each_line do |line|
				puts line
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

