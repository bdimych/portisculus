msgCount = ARGV[0].to_i
if msgCount <= 0
	raise "ERROR: usage: #$0 msgCount"
end

STDOUT.sync = true

totalSec = 10
if chld = fork
	puts "forked #{chld} from #$$"
	srand
	waitSec = 2 + rand * totalSec # если без добавки то всё таки слишком мало получается сигнал раньше чем создаётся at_exit
	puts "waitSec #{waitSec}"
	sleep waitSec
	puts "sending INT to #{chld}"
	Process.kill 'INT', chld
p Process.wait
p $?
	exit
end

puts Process.ppid

$msgDelay = totalSec.to_f/msgCount
puts "msgCount: #{msgCount}, totalSec: #{totalSec}, msgDelay: #$msgDelay"

module Kernel
	alias :realputs :puts
	def puts(*args)
		realputs *args
		if args[0] =~ /preparing for adding loop$/
			puts 'start delaying'
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

