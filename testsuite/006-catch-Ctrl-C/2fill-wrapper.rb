msgCount = ARGV[0].to_i
if msgCount <= 0
	raise "ERROR: usage: #$0 msgCount"
end
totalSec = 10
$msgDelay = totalSec.to_f/msgCount
puts "msgCount: #{msgCount}, totalSec: #{totalSec}, msgDelay: #$msgDelay"

srand

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

