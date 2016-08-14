#!/bin/bash
## changing file names
PARAMETERN=2 ##the number  of parameters given in the form like "-x n", currently it's 2
while getopts s: option ; do 
	case "$option" in
		s )
			startN=$OPTARG ;; #close interval
	
		\?)
			echo "If you're reading this, well, You're screwed. Totally and royally.";;
	esac
done
#checking interval
echo startN
#record file names in a array named fileNames and it's maximum index(starts from )
declare -a fileNames
fileNameIndex=0 #this variables should always be a int
tmpCounter=1
for arg in $@; do
	if ((  tmpCounter  <= PARAMETERN )); then
		((tmpCounter+=1))
		continue	
	fi
	fileNames[fileNameIndex]=$arg
	((fileNameIndex+=1))
done

(( endN = startN + fileNameIndex ))

for (( i=${startN}; i < ${endN}; i++)); do
	(( n =  i - startN ))
	tmp=${fileNames[${n}]}
	cp ${tmp} "run1_it0"${i}"_data.star"
done

echo "Job done, have a nice day."