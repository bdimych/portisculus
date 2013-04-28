#!/bin/bash

# backup stdout and redirect it to the stderr
exec 11>&1 1>&2

set -e -o pipefail

echo Count-bpm-by-hands.sh started



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

function result {
	echo Result \"$1\"
	echo $1 >&11
	exit
}

function echo3 {
	echo "$@" >&3
	sleep 0.1
}

function usage {
	echo 'Usage: "h" or "u" - usage, "p" - pause, home/left/right - seek 0/-10/+10 seconds, space - count, "d" - counting done, "r" - reset counter, "n" - just go next, save as: "-" skipped, "=" beatless, "q" or ctrl-c - exit'
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

echo Starting mplayer
echo
trap 'if tty -s; then stty echo; fi; echo3 quit' EXIT
exec 3> >(
	cd "$(dirname "$BYHANDS")"
	mplayer -slave -noautosub -quiet -identify "$(basename "$BYHANDS")" | perl -n -e '
		s/\r//g;
		if (s/\e\[A\e\[K//) { # cut terminal control sequences
			print if !/^$/
		}
		elsif (/^ID_([A-Z\d_]+)=/) { # print ID_ only for LENGTH
			print if $1 eq "LENGTH"
		}
		else {
			print
		}
	'
)
sleep 1 # give mplayer some time to start and print his banner
echo
echo File: "$BYHANDS"
reset
usage
echo3 loop 0 1 # infinite loop
echo PLAYING NOW - TURN SOUND ON!
echo



# main loop

while IFS='' read -p $'\r> ' -n1 -s k
do
	case $k in
		q) result quit ;;
		u|h) usage ;;
		r) reset ;;
		n) result next ;;
		-) result skip ;;
		=) result beatless ;;
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
			while read -p "Done, bpm is $bpmAver (Y, n, enter by (h)ands)? " -s -n1 k
			do
				[[ ! $k ]] && k=y # Enter means y
				echo $k
				case $k in
					y) result $bpmAver ;;
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



