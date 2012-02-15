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
	lastBpms=()
	bpmAver=0
	counter=-1
	echo Counter has been reset
}

exec 11>&1
exec 1>&2
echo count-bpm-by-hands.sh
echo starting mplayer
echo
trap 'stty echo; echo3 quit' EXIT
exec 3> >(mplayer -slave -loop 0 -quiet tmp.mp3 | perl -n -e 's/\r//g; if (s/\e\[A\e\[K//) {print if !/^$/} else {print}')
pause >tmp.txt
reset >>tmp.txt
usage >>tmp.txt
sleep 1
echo
cat tmp.txt
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
			if (( $SECONDS > 0 ))
			then
				bpm=$(($counter*60/$SECONDS))
				lastBpms=(${lastBpms[*]} +$bpm)
				if (( ${#lastBpms[*]} > 10 ))
				then
					unset lastBpms[0]
					bpmAver=$(( ( ${lastBpms[*]} ) / 10 ))
				fi
			fi
			printf 'Counter: %3u;   seconds: %2u;   bpm: %3u;   bpm average: %3u\n' $counter $SECONDS $bpm $bpmAver
			;;
			
		d)
			pause
			while true
			do
				echo -n "Done, bpm is $bpmAver (y|n|enter by (h)ands)? "
				while true
				do
					read -s -n1 k
					case $k in
						y)
							echo y
							break 3
							;;
						n)
							echo n
							break 2
							;;
						h)
							echo h
							while true
							do
								read -p 'Enter bpm: ' bpmAver
								[[ $bpmAver =~ ^[0-9]+$ ]] && break 2
								echo Only digits please
							done
					esac
				done
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

echo $bpmAver >&11

