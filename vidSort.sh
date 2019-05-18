#!/bin/bash

#vidSort v1.2
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
declare -a dirs=()

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
			echo "Requires at least 1 directory path"
			echo "Flags:"
			echo
			echo "-s, --sort		sort by duration (ascending)"
			echo "-sa				sort by duration (ascending)"
			echo "-sd				sort by duration (descending)"
			echo "-m, --match		only show files with matching durations"
			echo "-v, --verbose		verbose mode"
			echo "-h, --help		help"
			echo
			echo "Version 1.2"
			exit 0
			;;
		-*|--*)
			echo "bad option $1"
			exit 1
			;;
		*)
			#assume any non-option argument is a directory
			dirs+=("$1")
	esac
	shift
done

declare -a origVidNames=()
declare -a origVidDurations=()

#name reference variables
declare -n vidNames=origVidNames
declare -n vidDurations=origVidDurations

#build regex of all supported file extensionsRegex
declare -a extensions=("mov" "flv" "h261" "h263" "h264" "m4v" "m4a" "3gp" "3g2" "mj2" "mp2" "mp3" "mpeg" "mpeg1video" "mpeg2video" "mpegts" "mpegtsraw" "mpegvideo" "oga" "ogg" "ogv" "opengl" "opus" "oss" "swf" "wav" "webm")
#can also support webp, but theres issues with static ones.
extensionsRegex="\(.*mp4\\"

for i in "${extensions[@]}"
do
	extensionsRegex+="|.*"
	extensionsRegex+="$i"
	extensionsRegex+="\\"
done

extensionsRegex+=")"

if [ "${dirs[0]}" == "" ]
then
	echo "No path given"
	exit 1
fi

for dir in "${dirs[@]}"
do
	#make sure directory exists
	if ! [ -d "$dir" ]
	then
		echo "Invalid directory $dir"
		exit 1
	fi
	
	echo "working in $dir"
	cd "$dir"
	
	#get file list
	if [ "$verbose" == true ]
	then
		echo "getting files list"
	fi

	#temporarily setting the internal field seperator to the newline character so find works with whitespace. Hacky, works.
	IFS=$'\n'; set -f

	for i in $(find -maxdepth 1 -regex "$extensionsRegex"); #maxdepth 1 excludes subfolders. 0 excludes hidden files
	do
		newDuration=$(ffprobe -i "$i" -show_entries format=duration -v quiet -of csv="p=0")
		iNewDuration=${newDuration%.*}
		vidDurations+=($iNewDuration)
		vidNames+=("$i")
	done
	unset IFS; set +f #reset to normal
done

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
