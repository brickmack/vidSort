#!/bin/bash

#Command line utility to list duration and title of all files in a directory. Useful for manual file de-duplication

#Flags
#	-s, -sa (not yet implemented): sort by duration (ascending)
#	-sd (not yet implemented): sort by duration (descending)
#	-m: only show files with matching durations
#	-v: verbose (not yet implemented, always verbose)
#	-h: help (not yet implemented)

#Target directory must always be the first argument!


#make sure user gave a path (or could be -h/--help)
if [ $# -eq 0 ]
then
	echo "No path given"
	exit 1
fi

#make sure directory exists
if ! [ -d "$1" ]
then
	echo "Invalid directory"
	exit 1
fi

echo "working in " "$1"
cd "$1"

declare -a origVidNames=()
declare -a origVidDurations=()

declare -n vidNames=origVidNames
declare -n vidDurations=origVidDurations

#get file list
echo "getting files list"

#temporarily setting the internal field seperator to the newline character so find works with whitespace. Hacky, works.
IFS=$'\n'; set -f

for i in $(find -name '*.mp4' -or -name '*.mov');
do
	newDuration=$(ffprobe -i "$i" -show_entries format=duration -v quiet -of csv="p=0")
	iNewDuration=${newDuration%.*}
	vidDurations+=($iNewDuration)
	vidNames+=("$i")
done
unset IFS; set +f

length=${#vidDurations[@]}

matching=false
verbose=false
sorting=false
while test $# -gt 0
do
	case "$2" in
		-m)
			matching=true
			;;
	        -v)
			verbose=true
			;;
		-s)
			sorting=true
			;;
		-h) echo "help"
			;;
		--*) echo "bad option $2"
			;;
		*) echo "argument $2"
			;;
	esac
	shift
done

if [ "$matching" == true ]
then
	echo "matching"

	#loop through array and copies values to second array only if the same duration exists twice

	declare -a newVidNames=()
	declare -a newVidDurations=()

	echo "pruning"

	newLength=0

	for ((i = 0; i<$length; i++))
	do
		for((j = 0; j<$length; j++))
		do
			if ((${vidDurations[i]} == ${vidDurations[j]} && $i != $j))
			then
				#copy all values to new arrays
				newVidNames+=("${vidNames[$i]}")
				newVidDurations+=(${vidDurations[$i]})
				newLength=$(($newLength+1))

				break
			fi
		done
	done

	length=$newLength

	declare -n vidNames=newVidNames
	declare -n vidDurations=newVidDurations
fi

if [ "$sorting" == true ]
then
	echo "sorting" $length "files"
	
	#insertion sort
	for((i=1;i<$length;i++))
	do
		j=$i-1
		tempDur=${vidDurations[$i]}
		tempName=${vidNames[$i]}
		while((j>=0 && vidDurations[j]>tempDur))
		do
			vidDurations[$j+1]=${vidDurations[$j]}
			vidNames[$j+1]=${vidNames[$j]}
			j=$j-1
		done
		vidDurations[j+1]=$tempDur
		vidNames[j+1]=$tempName
	done
fi

for ((i = 0; i<$length; i++))
do
	echo $i "${vidDurations[i]}" "${vidNames[i]}"
done
