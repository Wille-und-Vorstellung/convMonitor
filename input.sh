#!/bbin/bash
PARAMETERN=2
tmpCounter=0
fileNameIndex=0
for arg in $@; do
	if ((  tmpCounter  >= PARAMETERN )); then
		fileNames[fileNameIndex]=$arg
		((fileNameIndex+=1))
	fi
	((tmpCounter+=1))
done

for (( i=0; i < fileNameIndex; i++ )); do
	tmp=${fileNames[${i}]}
	echo ${tmp}
done
