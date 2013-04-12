msgCount = ARGV[0].to_i
if msgCount <= 0
	raise "ERROR: usage: #$0 msgCount"
end

STDOUT.sync = true

totalSec = 10
$msgDelay = totalSec.to_f/msgCount
puts "msgCount: #{msgCount}, totalSec: #{totalSec}, msgDelay: #$msgDelay"

if chld = fork
	puts "parent #$$ child #{chld}"
	trap('USR1') {
		puts 'USR1 received'
		srand
		waitSec = rand * totalSec
		puts "waitSec #{waitSec}"
		sleep waitSec
		puts "sending INT to #{chld}"
		Process.kill 'INT', chld
		Process.wait
		if $?.exitstatus != 0
			raise "child exitstatus nonzero: #{$?.inspect}"
		end
		exit
	}
	sleep totalSec * 2
	raise 'totalSec*2 seconds still no signal'
end

module Kernel
	alias :realputs :puts
	def puts(*args)
		realputs *args
		if args[0] =~ /preparing for adding loop$/
			ppid = Process.ppid
			puts "start delaying, sending USR1 to #{ppid}"
			Process.kill 'USR1', ppid
			$doDelay = true
		end
		if $doDelay
			sleep $msgDelay
		end
	end
end

require './2-fill-player.rb'

if not $doDelay
	raise '$doDelay was not set'
end

