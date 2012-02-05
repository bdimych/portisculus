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
		skip = line.slice!(/^-/)
		path, bpm = line.chomp.split(/\s*:\s*/)
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
puts "db loaded: total: #{db.keys.size}, nonexistent: #{dbStat[:nonexistent]}, directories: #{dbStat[:dirs]}, files: #{dbStat[:files]}, without bpm: #{dbStat[:withoutBpm]}"













puts 'writing db'
File.open "#{dbFile}", 'w' do |fh|
	db.keys.sort.each do |path|
		fh.puts "#{db[path][:skip]}#{path}: #{db[path][:bpm]}"
	end
end

puts 'the end'

