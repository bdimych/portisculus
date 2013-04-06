msgCount = ARGV[0].to_i
if msgCount <= 0
	raise "ERROR: usage: #$0 msgCount"
end
puts "msgCount is #{msgCount}"

module Kernel
	alias :realputs :puts
	def puts(*args)
		realputs 'aaa'
		realputs *args
		realputs 'bbb'
	end
end

require './2-fill-player.rb'

