#!/bin/bash

# backup stdout and redirect it to the stderr
exec 11>&1 1>&2

set -e -o pipefail

echo count-bpm-by-hands.sh started



# check

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

if [[ ! -s $BYHANDS ]]
then
	echo ERROR: BYHANDS environment variable must contain path to an existent file: $BYHANDS
	exit 1
fi



# functions

function echo3 {
	echo "$@" >&3
	sleep 0.1
}

function usage {
	echo Usage: h - usage, p - pause, home/left/right - seek 0/-10/+10 seconds, space - count, d - counting done, r - reset counter, q or ctrl+c - quit
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
	bpmAver=
	counter=-1
	echo Counter has been reset
}



# init

echo starting mplayer
echo
trap 'stty echo; echo3 quit' EXIT
exec 3> >(cd "$(dirname "$BYHANDS")"; mplayer -slave -loop 0 -noautosub -quiet "$(basename "$BYHANDS")" | perl -n -e 's/\r//g; if (s/\e\[A\e\[K//) {print if !/^$/} else {print}')
reset >tmp.txt
usage >>tmp.txt
sleep 1 # give mplayer some time to start and print his banner
echo
cat tmp.txt
echo PLAYING NOW - TURN SOUND ON!
echo



# main loop

while IFS='' read -p $'\r'"$BYHANDS > " -n1 -s k
do
	case $k in
		h) usage ;;
		r) reset ;;
		'') echo ;; # enter
		
		' ')
			if [[ $paused ]]
			then
				echo Counting disabled when paused
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
			printf 'Counter: %3u;   seconds: %2u;   bpm: %3u;   average bpm result: %3s\n' $counter $SECONDS $bpm $bpmAver
			;;
			
		d)
			if [[ ! $bpmAver ]]
			then
				echo No bpm result yet
				continue
			fi
			pause
			while read -p "Done, bpm is $bpmAver (y, n, enter by (h)ands)? " -s -n1 k
			do
				echo $k
				case $k in
					y) break 2 ;;
					n) break ;;
					h)
						while read -p 'Enter bpm (positive number): ' bpmAver
						do
							[[ $bpmAver =~ ^[0-9]+$ ]] && (( $bpmAver > 0 )) && bpmAver=$((bpmAver)) && break
						done
				esac
			done
			;;

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
			while read -p 'Quit without bpm (y, n)? ' -s -n1 k
			do
				echo $k
				case $k in
					y) exit ;;
					n) break
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

	esac
done



# print result to the original stdout

echo $bpmAver >&11



