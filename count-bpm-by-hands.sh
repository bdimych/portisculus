#!/bin/bash

set -e -o pipefail

exec 11>&1
exec 1>&2

trap 'stty echo; echo3 quit' EXIT

function player {
	'/cygdrive/c/Program Files (x86)/SMPlayer/mplayer/mplayer.exe' -slave -loop 0 -quiet tmp.mp3 | perl -n -e 's/\r//g; if (s/\e\[A\e\[K//) {print if !/^$/} else {print}'
}

function echo3 {
	echo "$@" >&3
	sleep 0.1
}

function usage {
	echo 'Usage: h - usage, p - pause, home/left/right - seek 0/-10/+10 seconds, space - count, d - counting done, r - reset counter, q - quit'
}

function seek {
	echo3 pausing_keep seek $1 $2
}

function pause {
	if [[ ! $paused ]]
	then
		echo3 pause
		echo Paused
		paused=1
	fi
}

function unpause {
	if [[ $paused ]]
	then
		echo3 pause
		echo Playing
		paused=
	fi
}

exec 3> >(player)
pause >/dev/null
sleep 1
echo
echo Paused
usage
echo

bpm=; counter=-1
while IFS='' read -p $'\r> ' -n1 -s k
do
	case $k in
		' ')
			(( $counter == -1 )) && SECONDS=0
			counter=$(($counter+1))
			(( $SECONDS > 0 )) && bpm=$(($counter*60/$SECONDS))
			printf 'Counter: %3u;   seconds: %2u;   bpm: %3u\n' $counter $SECONDS $bpm
			;;

		r)
			bpm=; counter=-1
			echo Counter has been reset
			;;
			
		'') echo ;; # enter
		
		p)
			if [[ $paused ]]
			then
				unpause
			else
				pause
			fi
			;;

		q)
			wasPaused=$paused
			pause >/dev/null
			echo -n 'Quit without bpm (y|n)? '
			while true
			do
				read -s -n1 k
				case $k in
					y) echo y; exit ;;
					n) echo n; break
				esac
			done
			[[ $wasPaused ]] || unpause >/dev/null
			;;

		$'\e')
			read -n1 -t0.1 k || continue
			[[ $k == [ ]]    || continue
			read -n1 -t0.1 k || continue
			if [[ $k == H ]] # \e[H home
			then
				seek 0 2
			elif [[ $k == D ]] # \e[D left arrow
			then
				seek -10
			elif [[ $k == C ]] # \e[C right arrow
			then
				seek +10
			fi
			;;

		h) usage ;;
		
	esac
done

echo $bpm >&11

