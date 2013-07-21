#!/usr/bin/ruby

require_relative 'lib.rb'



start






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
	log "scanning directory #{dir}"
	Find.find dir do |f|
		next if ! File.file? f or f !~ /\.mp3$/i
		dbAdd f
	end
end
pass1 = $db.keys.sort.select do |f|
	f.exists? and !f.dir? and !f.skipped? and !f.beatless? and !f.bpmOk? and $db[f][:bpm] !~ /soundstretchFailed|byhands/
end
pass1.each_with_index do |f, i|
	log "doing file #{i+1} of #{pass1.count}: #{f}"

	FileUtils.copy_entry f, './tmp.mp3', false, false, true

	cmd = %w(ffmpeg -nostdin -y -i tmp.mp3 tmp-decoded.wav)
	log cmd.join ' '
	if ! system *cmd
		raise "error decoding mp3 #$?"
	end

	bpm = 'soundstretchFailed'
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
writeDb







# prompt for second pass

puts "\nfirst pass done"
pass2 = $db.keys.select do |f|
	f.withoutBpm?
end
# сортирую:
# 1. слушать приятнее в случайном порядке
# 2. те которые я сам специально отметил byhands первее
srand
pass2.sort! do |a, b|
	if $db[a][:bpm] == 'byhands' and $db[b][:bpm] != 'byhands' then
		-1
	elsif $db[a][:bpm] != 'byhands' and $db[b][:bpm] == 'byhands' then
		1
	else
		rand < 0.5 ? -1 : 1
	end
end
begin
	if pass2.count == 0
		puts 'all existent nonskipped files has bpm'
		exit
	else
		while true
			case readChar "#{pass2.count} files remains without bpm, count them by hands (Y, n, (l)ist)? ", [?y, ?n, ?l]
				when ?y
					break
				when ?n
					exit
				when ?l
					puts pass2.map{|f| "[#{$db[f][:bpm]}] #{f}"}.sort
					puts
			end
		end
	end
ensure
	puts
end






# second pass - count by hands

log 'second pass - count by hands'
puts
pass2.each_with_index do |f, i|
	progress = "Second pass: #{i+1} of #{pass2.count}"
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
			msg = "bpm = #{bpm}"
		when 'next'
		when 'skip'
			puts
			puts "file #{f}"
			if askYesNo 'save as skipped?'
				dbSet f, :flag, '-'
				msg = 'skipped'
			end
		when 'beatless'
			puts
			puts "file #{f}"
			if askYesNo 'save as beatless?'
				dbSet f, :flag, '='
				msg = 'beatless'
			end
		when 'quit'
			exit
		else
			raise 'unknown byhands result'
	end
	puts
	writeDb
	puts
	if ! msg.empty?
		puts msg
		exit if 'q' == readChar('press any key to continue or "q" to quit ')
		puts
	end
end







log 'the end'

