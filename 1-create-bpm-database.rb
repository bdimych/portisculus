#!/usr/bin/ruby

require 'lib.rb'




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
puts
$db.keys.sort.each do |f|
	next if ! f.withoutBpm?

	pass2[0] += 1
	progress = "Second pass: #{pass2[0]} from #{pass2[1]}"
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
	puts
end







log 'the end'
