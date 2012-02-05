#!/usr/bin/ruby

dbFile = 'bpm-database.txt';

puts 'reading db';
db = {}
dbStat = {:nonexistent => 0, :dirs => 0, :files => 0, :withoutBpm => 0}
if ! File.exists? dbFile
	puts "bpm database file #{dbFile} does not exist"
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
puts "db loaded: paths total: #{db.keys.size}, nonexistent: #{dbStat[:nonexistent]}, directories: #{dbStat[:dirs]}, files total: #{dbStat[:files]}, without bpm: #{dbStat[:withoutBpm]}"




require 'Find'
db.keys.sort.each do |dir|
	next if ! File.directory? dir
	puts "doing directory #{dir}"
	Find.find dir do |f|
		next if ! File.file? f or f !~ /\.mp3$/i or (db[f] and db[f][:bpm])
		puts "doing file #{f}"
	end
end







puts 'writing db'
File.open "#{dbFile}", 'w' do |fh|
	db.keys.sort.each do |path|
		skip = db[path][:skip] ? '- ' : ''
		fh.puts "#{skip}#{path}" + (File.directory?(path) ? '' : ": #{db[path][:bpm]}")
	end
end

puts 'the end'

