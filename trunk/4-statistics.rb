#!/usr/bin/ruby

require_relative 'lib.rb'



start true



log 'getting already in player array'

aip = [] # already in player array
$db.each do |f, hash|
	if hash[:inPlayer]
		hash[:inPlayer][:origPath] = f
		aip.push hash[:inPlayer]
	end
end
if aip.empty?
	log 'there are no songs in player, nothing to do'
	exit
end

lsU = %x(ls -U '#$playerDir').split "\n"
aip.sort! do |a, b|
	raise "no #{a[:name]} in lsU" if ! lsU.include? a[:name]
	raise "no #{b[:name]} in lsU" if ! lsU.include? b[:name]
	lsU.index(a[:name]) <=> lsU.index(b[:name])
end





log 'start gathering statistics'

bpms = aip.map{|h| h[:bpm]}
bpms_NoBls_Int = bpms.select{|bpm| bpm != 'BLS'}.map{|bpm| bpm.to_i}
log "bpm values: #{bpms.join '  '}\nmin: #{bpms_NoBls_Int.min}\nmax: #{bpms_NoBls_Int.max}\naver: #{bpms_NoBls_Int.reduce(:+)/bpms_NoBls_Int.count}"

neighbouringBpmDiff = []
for i in 0..(aip.count-2)
	next if aip[i][:bpm] == 'BLS' or aip[i+1][:bpm] == 'BLS'
	neighbouringBpmDiff.push( (aip[i][:bpm].to_i - aip[i+1][:bpm].to_i).abs )
end
log "neighbouringBpmDiff: #{neighbouringBpmDiff.join '  '}\nmin: #{neighbouringBpmDiff.min}\nmax: #{neighbouringBpmDiff.max}\naver: #{neighbouringBpmDiff.reduce(:+)/neighbouringBpmDiff.count}"








