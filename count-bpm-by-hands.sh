#!/bin/bash

set -e -o pipefail

if ! mplayer &>/dev/null
then
	echo ERROR: could not find mplayer
	exit 1
fi

if ! perl --help &>/dev/null
then
	echo ERROR: could not find perl
	exit 1
fi

if [[ ! -s tmp.mp3 ]]
then
	echo ERROR: could not find tmp.mp3
	exit 1
fi

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

function reset {
	bpm=0
	counter=-1
	echo Counter has been reset
}

exec 11>&1
exec 1>&2
trap 'stty echo; echo3 quit' EXIT
exec 3> >(mplayer -slave -loop 0 -quiet tmp.mp3 | perl -n -e 's/\r//g; if (s/\e\[A\e\[K//) {print if !/^$/} else {print}')
pause >/dev/null
sleep 1
echo
reset
echo Paused
usage
echo

while IFS='' read -p $'\r> ' -n1 -s k
do
	case $k in
		' ')
			if [[ $paused ]]
			then
				echo "Counting disabled when paused"
				continue
			fi
			(( $counter == -1 )) && SECONDS=0
			counter=$(($counter+1))
			(( $SECONDS > 0 )) && bpm=$(($counter*60/$SECONDS))
			printf 'Counter: %3u;   seconds: %2u;   bpm: %3u\n' $counter $SECONDS $bpm
			;;
			
		d)
			pause
			echo -n "Done, bpm is $bpm (y|n|(e)nter by hands)? "
			while true
			do
				read -s -n1 k
				case $k in
					y)
						echo y
						break 2
						;;
					n)
						echo n
						reset
						break
						;;
					e)
						echo e
						while true
						do
							read -p 'Enter bpm: ' bpm
							[[ $bpm =~ ^[0-9]+$ ]] && break 3
							echo Only digits please
						done
				esac
			done
			;;

		r) reset ;;
			
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
			pause
			echo -n 'Quit without bpm (y|n)? '
			while true
			do
				read -s -n1 k
				case $k in
					y) echo y; exit ;;
					n) echo n; break
				esac
			done
			[[ $wasPaused ]] || unpause
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

