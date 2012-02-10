#!/bin/bash

trap 'stty echo' EXIT
echo space - count, enter - counting done, r - restart counting, p - pause, left/right - seek -/+10 seconds >&2
while IFS='' read -n1 -s k
do
	if [[ $k == ' ' ]]
	then
		echo space >&2
	elif [[ ! $k ]]
	then
		echo quit
		break
	elif [[ $k == r ]]
	then
		echo restart >&2
	elif [[ $k == p ]]
	then
		echo pause
		echo pause >&2
	elif [[ $k == $'\e' ]]
	then
		read -n1 k
		[[ $k == [ ]] || continue
		read -n1 k
		if [[ $k == D ]] # \e[D left arrow
		then
			echo seek -10
		elif [[ $k == C ]] # \e[C right arrow
		then
			echo seek +10
		fi
	fi
done | /cygdrive/c/Program\ Files\ \(x86\)/SMPlayer/mplayer/mplayer.exe tmp.mp3 -slave -loop 0 -quiet >&2

echo bebebe

