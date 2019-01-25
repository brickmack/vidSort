#!/bin/bash

#vidSort v1.1
#Command line utility to list duration and title of all files in a directory. Useful for manual file de-duplication

#Flags
#	-s, -sa: sort by duration (ascending)
#	-sd: sort by duration (descending)
#	-m: only show files with matching durations
#	-v: verbose
#	-h: help

#make sure user gave some arguments
if [ $# -eq 0 ]
then
	echo "No arguments given"
	exit 1
fi

#read arguments
matching=false
verbose=false
sorting=0 #0 = no sort, 1 = ascending, -1 = descending
dir=""
while test $# -gt 0
do
	case "$1" in
		-m|--match)
			matching=true
			;;
		-v|--verbose)
			verbose=true
			;;
		-s|-sa|--sort)
			sorting=1 #default to ascending if no sort order is explicitly given
			;;
		-sd)
			sorting=-1
			;;
		-h|--help)
			echo "Usage: ./vidSort.sh [FILE] ... [OPTION]"
			echo "Command line utility to list duration and title of all files in a directory. Useful for manual file de-duplication"
			echo "Takes exactly 1 directory path"
			echo "Options:"
			echo
			echo "-s, --sort		sort by duration (ascending)"
			echo "-sa				sort by duration (ascending)"
			echo "-sd				sort by duration (descending)"
			echo "-m, --match		only show files with matching durations"
			echo "-v, --verbose		verbose mode"
			echo "-h, --help		help"
			echo
			echo "Version 1.1"
			exit 0
			;;
		-*|--*)
			echo "bad option $1"
			exit 1
			;;
		*)
			#assume any non-option argument is a directory. We can only take 1 directory argument, so make sure the directory variable doesn't already have something assigned
			if [ "$dir" == "" ]
			then
				dir="$1"
			else
				echo "Too many arguments"
				exit 1
			fi
	esac
	shift
done

if [ "$dir" == "" ]
then
	echo "No path given"
	exit 1
fi

#make sure directory exists
if ! [ -d "$dir" ]
then
	echo "Invalid directory $dir"
	exit 1
fi

echo "working in $dir"
cd "$dir"

declare -a origVidNames=()
declare -a origVidDurations=()

#name reference variables
declare -n vidNames=origVidNames
declare -n vidDurations=origVidDurations

#get file list
if [ "$verbose" == true ]
then
	echo "getting files list"
fi

#temporarily setting the internal field seperator to the newline character so find works with whitespace. Hacky, works.
IFS=$'\n'; set -f

for i in $(find -maxdepth 1 -name '*.mp4' -or -name '*.mov'); #maxdepth 1 excludes subfolders. 0 excludes hidden files
do
	newDuration=$(ffprobe -i "$i" -show_entries format=duration -v quiet -of csv="p=0")
	iNewDuration=${newDuration%.*}
	vidDurations+=($iNewDuration)
	vidNames+=("$i")
done
unset IFS; set +f #reset to normal

length=${#vidDurations[@]}

if [ "$matching" == true ]
then
	#loop through array and copies values to second array only if the same duration exists twice
	
	if [ "$verbose" == true ]
	then
		echo "matching"
	fi

	declare -a newVidNames=()
	declare -a newVidDurations=()

	newLength=0

	for ((i = 0; i<$length; i++))
	do
		for ((j = 0; j<$length; j++))
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

	#reassign name references
	declare -n vidNames=newVidNames
	declare -n vidDurations=newVidDurations
fi

if (($sorting != 0)) #if sorting is enabled
then
	if [ "$verbose" == true ]
	then
		if (($sorting == 1))
		then
			sortModeHR="ascending"
		else
			sortModeHR="descending"
		fi
		echo "sorting $length files, $sortModeHR"
	fi
	
	#insertion sort
	for((i=1;i<$length;i++))
	do
		j=$i-1
		tempDur=${vidDurations[$i]}
		tempName=${vidNames[$i]}
		while((j>=0 && (($sorting == 1 && vidDurations[j]>tempDur) || ($sorting == -1 && vidDurations[j]<tempDur))))
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
