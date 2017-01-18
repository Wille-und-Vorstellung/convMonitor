#!/bin/bash
####################################################
#Mk04_plus: 2D-classification + additonal analysis & plot + track
#input parameter: 									#
#	1.the number of classes; like "-n x"                                     			#
#	2.number of particles to be monitored;like  "-p y"				#
#	3..all those star files;like "manual_it???_data.star"			#
#Log files:										#
#	1.${LOGFILE}									#
#	2.testLog.log									#
#output:										#
#	1.statisticMk04.dat								#
#	2.RogueParticles.star								#
#	3.PrudentParticles.star 							#
#	4.AnalysisPlus.dat 								#
####################################################
#Macros and conventions:								#
#	1.HEADERL	 								#
#	2.TCOLUMN 									#
#	3.PARAMETERN								#
#	4.EXTRACTN									#
#	5.VASTART									#
#	6.VAEND									#
#	7.INC, column number of  _rlnImageName					#
#	8.CXC, column number of  _rlnCoordinateX 					# 
#	9.CYC, column number of  _rlnCoordinateY 					# 
#	10.MNC, column number of  _rlnMicrographName 				# 
#	11.CNC, column number of  _rlnClassNumber 				# 
#	12.NCC, ~ _rlnNormCorrection 				#
#	13.LLCC, ~ _rlnLogLikeliContribution		#
#	14.MVPDC, ~ _rlnMaxValueProbDistribution	#
#	15.NSSC, ~ _rlnNrOfSignificantSamples		#
####################################################
##IMPORTANT NOTICE: do check those macros below before running, or unexpected should happen
LOGFILE=Mk04_lite.log
OUTIMG=d02_r01.png
PARAMETERN=4
EXTRACTN=20
HEADERL=29
TCOLUMN=22

VASTART=1 #close interval
VAEND=10 #open interval

INC=10 #_rlnImageName #10
CXC=11 #_rlnCoordinateX #11 
CYC=12 #_rlnCoordinateY #12 
MNC=13 #_rlnMicrographName #13 
CNC=22 #_rlnClassNumber #20  //hazard?(there was once 14)
NCC=13 #_rlnNormCorrection #21
LLCC=23 #_rlnLogLikeliContribution #22 
MVPDC=25 #_rlnMaxValueProbDistribution #23 
NSSC=24 #_rlnNrOfSignificantSamples #24 
#################################################################################################

##function FileProcessing
#input:1. fileNames( global access, I know  it's not good to use global variable,trust me I know what I'm doing)
#	2. totalParticleN
#	3. fileNameIndex( global acccess too )
#	4. class number( as in classN )
#output: global return to the corresponding "toPlotParticle$i" arrays
#Notice: 1.the class number must be at the 22rd colume of every raw in the input files
#	    2.in the input file, one line corresponds to one partilce and this relation changes not in every file
function FileProcessing(){
	
	local _tempPath=abc
	local _tempID
	local _classN=$2
	local _particleN=$1
	local _rowN=0
	local _HEADLENGTH=${HEADERL} #macrolink 25, 20 #supposedly, heads in every files we get is of the same length, which is 30 here
	local _TARGETCOLUMN=${TCOLUMN}
	local _tmp

	echo "Check Point 3" >> ${LOGFILE}
	for (( i = 0; i < fileNameIndex; i++ )) ; do #every file
		_tempPath=${fileNames[i]}
		for (( j = 0; j < _particleN; j++ )); do # every particle( corresponds to lines in the files  ) 
			(( _rowN = j + _HEADLENGTH + 1 ))
			#echo "read files:  ${_tempPath}"
			_tmp=$( awk -v x=${_rowN} -v y=${_TARGETCOLUMN} '{if ( NR==x ) { print  $y} else {} }' < ${_tempPath} )
			eval "toPlotParticle${j}"[i]=${_tmp}

			if (( i != 0 )); then
				track1=$( awk -v x=${_rowN} -v y=${NCC} '{if ( NR==x ) { print  $y} else {} }' < ${_tempPath} )
				track2=$( awk -v x=${_rowN} -v y=${NSSC} '{if ( NR==x ) { print  $y} else {} }' < ${_tempPath} )
				track3=$( awk -v x=${_rowN} -v y=${MVPDC} '{if ( NR==x ) { print  $y} else {} }' < ${_tempPath} )
				track4=$( awk -v x=${_rowN} -v y=${LLCC} '{if ( NR==x ) { print  $y} else {} }' < ${_tempPath} )

				eval "NCCArray${j}"[i]=${track1}
				eval "NSSCArray${j}"[i]=${track2}
				eval "MVPDCArray${j}"[i]=${track3}
				eval "LLCCArray${j}"[i]=${track4}
			fi

		done
	done

	echo "Check Point 4" >> ${LOGFILE}
	return 0
}
##just a simple quick sort 
#input: 1.$1:start index(close interval ); 2.$2: end index(close interval);3. toSort array(global access); 4. sortIndex array(global access) 
#notice: pivot selection: the average of start index and end index
#global access alert: the origin array to be sorted is set as global variable and the sortIndex array
function Qsort(){
	local _startIndex=$1
	local _endIndex=$2
	local _pivot=0
	local _devide=0
	local _ldevide=0
	local _rdevide=0
	local _tmp=0
	local tmpl=0
	local tmpr=0
	local _left=0
	local _right=0

	#schecking halting condition
	if (( _startIndex >= _endIndex )); then #only one entry left in the given interval
		echo "halt, left:"${_startIndex}", right: "${_endIndex} >> testLog.log
		return 0
	fi
	#get _pivot ( the last entry of current interval )
	_tmp="toSort[${_endIndex}]"
	_tmp=${!_tmp}
	_pivot=$( echo " scale=3; ${_tmp} + 0 " | bc ) 

	echo "left:"${_startIndex}", right: "${_endIndex}", pivot: "${_tmp} >> testLog.log
	#partition
	(( _left = _startIndex -1))
	(( _right = _startIndex))
	for (( _right=_startIndex; _right < _endIndex; _right++ )); do

		tmpr="toSort[${_right}]"
		tmpr=${!tmpr}
		if [ $( echo " ${tmpr} <= ${_pivot}" | bc ) -eq 1 ]; then
			(( _left += 1 ))
			#swap entry[_left] and entry[_right], global access alert!
			if (( _left < _right )); then
				_tmp=${toSort[${_left}]}
				toSort[${_left}]=${toSort[${_right}]}
				toSort[${_right}]=${_tmp}
				#swap the sort indexs as well
				_tmp=${sortIndex[${_left}]}
				sortIndex[${_left}]=${sortIndex[${_right}]}
				sortIndex[${_right}]=${_tmp}
				echo "swap: "${_left}" <-> "${_right} >> testLog.log
			fi
		fi 

	done
	#swap _left+1 and _endIndex
	(( _left += 1 ))
	_tmp=${toSort[${_left}]}
	toSort[${_left}]=${toSort[${_endIndex}]}
	toSort[${_endIndex}]=${_tmp}
	#swap the sort indexs as well
	_tmp=${sortIndex[${_left}]}
	sortIndex[${_left}]=${sortIndex[${_endIndex}]}
	sortIndex[${_endIndex}]=${_tmp}
	echo "swap: "${_left}" <-> "${_endIndex} >> testLog.log
	(( _devide = _left ))

	echo "devide: "${_devide} >> testLog.log
	(( _ldevide = _devide - 1 ))
	(( _rdevide = _devide + 1 ))
	Qsort ${_startIndex} ${_ldevide}
	Qsort  ${_rdevide} ${_endIndex}
	
	return 0
}

####main
##phase 1: reading all files and organize them into predetermined format
#read in and recognise the class number and store those file names
touch ${LOGFILE}
cat /dev/null > ${LOGFILE}
touch RogueParticles.star
cat /dev/null > RogueParticles.star
cat /dev/null > testLog.log
touch PrudentParticles.star
cat /dev/null > PrudentParticles.star
touch AnalysisPlus.dat
cat /dev/null > AnalysisPlus.dat

while getopts n:p: option ; do
	case "$option" in
		n )
			classN=$OPTARG ;;
		p)	
			totalParticleN=$OPTARG;; 
		\?)
			echo "If you're reading this, well, You're screwed. Totally and royally.";;
	esac
done
#record file names in a array named fileNames and it's maximum index(starts from )
declare -a fileNames
fileNameIndex=0 #this variables should always be a int
paraN=2 ##the number  of parameters given in the form like "-x n", currently it's 2
tmpCounter=1
for arg in $@; do
	if ((  tmpCounter  > PARAMETERN )); then
		fileNames[fileNameIndex]=$arg
		((fileNameIndex+=1))
	fi
	((tmpCounter+=1))
done

echo "Class Number: ${classN}" >> ${LOGFILE}
echo "particle number: ${totalParticleN}" >> ${LOGFILE}
echo "Check Point 1" >> ${LOGFILE}
## check point 1 end
#allocate  array for statistic result, one array for each particle( I was always wandering why there's  no 2-dimensional array in bash, a embarrassment really)
for (( i = 0; i < totalParticleN ; i++ )); do
	declare -a toPlotParticle$i
	declare -a NCCArray$i
	declare -a LLCCArray$i
	declare -a MVPDCArray$i
	declare -a NSSCArray$i

	for (( j = 0; j <fileNameIndex; j++ )); do # initialize all array entries( if only we could just use a matrix, like I  said, a real  embarrassment)
		eval "toPlotParticle$i"[j]=1
		eval "NCCArray$i"[j]=1
		eval "LLCCArray$i"[j]=1
		eval "MVPDCArray$i"[j]=1
		eval "NSSCArray$i"[j]=1
	done
done
echo "Check Point 2" >> ${LOGFILE}
#extract and organize the class number of every partilce at every run(files)
FileProcessing ${totalParticleN} ${classN}
#the "toPlotParticle$x" should all be modified by now

echo "Check Point 5" >> ${LOGFILE}
##Phase 2: plot those organized through curve fitting
#step1: prepare the correct input .dat file for gnuplot
touch statisticMk04.dat
cat /dev/null > statisticMk04.dat
temp=null
for (( i = 0; i < fileNameIndex; i++ )); do
	echo -ne "${i}" >> statisticMk04.dat
	for (( j = 0; j < totalParticleN ; j++ )); do
		(( temp =  "toPlotParticle${j}"[i] ))
		echo -ne " ${temp}" >> statisticMk04.dat
	done
	echo -ne "\n" >> statisticMk04.dat
done
echo "Check Point 6" >> ${LOGFILE}
#step2:assemble the suitable command for gnuplot
linepointSetting=' w lp pt 1'
inputFileSetting='"statisticMk04.dat" using 1:'
for (( i = 0; i < totalParticleN - 1; i++ )); do
	(( parameterClass=i+2 ))
	(( parameterTitle=i+1 ))
	plotCmd=${plotCmd}${inputFileSetting}${parameterClass}${linepointSetting}, #"\"Particle ${parameterTitle}\"",
done
(( parameterClass=totalParticleN+1))
(( parameterTitle=totalParticleN ))
plotCmd=${plotCmd}${inputFileSetting}${parameterClass}${linepointSetting} #"\"Particle ${parameterTitle}\""
#step3: invoke gnuplot and rock!
echo "gnuplot cmd: "$plotCmd >> ${LOGFILE}
gnuplot -persist << EOF
set xrange[0:${fileNameIndex}];
set yrange[0:${classN}];
set key off;
set output ${OUTIMG};
set xlabel "Iteration number";
set ylabel "particle class";
#plot "statistic.dat" using 1:2 w lp pt 1 title "class 1", "statistic.dat" using 1:3 w lp pt 2 title "class 2", "statistic.dat" using 1:4 w lp pt 3 title "class 3"
plot ${plotCmd}
EOF
echo "Check Point 7" >> ${LOGFILE}
##Phase 3: calculate variances anyway
#define variance array: for segmental variance storage should the need arises
for (( i = 0; i < totalParticleN; i++ )); do
	declare -a particleVariance${i}
	for (( j = 0; j < fileNameIndex; j++ )); do # initialization
		eval "particleVariance${i}"[j]=0
	done
done
#calculate variances on all the runs,and store at entry 1, while entry 0 holds the average
tmp=0
for (( i = 0; i < totalParticleN; i++ )); do #average
	sum=0
	for (( j = VASTART ; j < VAEND; j++ )); do
		(( tmp = "toPlotParticle${i}"[j] ))
		(( sum+=tmp ))
	done
	tmp=$( echo "scale=3; ${sum} / ${fileNameIndex}"  |  bc )
	eval "particleVariance${i}"[0]=${tmp}
done

##special treat for you motherF**ker
echo "special treat: average" >> ${LOGFILE}
for (( i=0; i<totalParticleN; i++ )); do
	tmp="particleVariance${i}" 
	tmpx=${tmp}"[0]"
	echo -n ${!tmpx}"  " >> ${LOGFILE}
done
echo " " >> ${LOGFILE}

for (( i = 0; i < totalParticleN; i++ )); do #variance 
	sum=0
	for (( j = VASTART; j < VAEND; j++ )); do
		tmp="toPlotParticle${i}" #bash does not support float operating in (()), so we deal with it as string
		tmp=${tmp}"[$j]"
		x=${!tmp}
		tmp="particleVariance${i}"
		tmp=${tmp}"[0]"
		y=${!tmp}
		#(( x="toPlotParticle${i}"[j] ))
		#(( y="particleVariance${i}"[0] ))
		tmp=$( echo " scale=3; ${x} - ${y} " |  bc )
		tmp=$( echo " scale=3; ${tmp}*${tmp} "  | bc )
		sum=$( echo " scale=3; ${sum}+${tmp}" | bc  )
		#(( tmp = "toPlotParticle${i}"[j]  -  "particleVariance${i}"[0] ))
		#(( tmp = tmp*tmp ))
		#(( sum+=tmp ))
	done
	tmp=$( echo "scale=3; ${sum} / ${fileNameIndex}"  |  bc )
	eval "particleVariance${i}"[1]=${tmp}
done
##
echo "special treat: variance" >> ${LOGFILE}
for (( i=0; i<totalParticleN; i++ )); do
	tmp="particleVariance${i}"
	tmpx=${tmp}"[1]"
	echo -n ${!tmpx}"  " >> ${LOGFILE}
done
echo " " >> ${LOGFILE}

echo "Check Point 8" >> ${LOGFILE}
##Phase 3+: counting oscillations in given interval(store an particleVariance[2])
base=0
for (( i = 0; i < totalParticleN; i++ )); do #average
	sum=0
	for (( j = VASTART ; j < VAEND-1; j++ )); do
		(( base = "toPlotParticle${i}"[j] )) #it's not float so we can write like this
		(( tmp = "toPlotParticle${i}"[j+1]))
		#echo "oscillation: index: "${j}", base: "${base}", tmp"${tmp} >> ${LOGFILE}
		if (( tmp != base )); then # class oscillation detected
			(( sum += 1 ))
		fi
	done
	
	eval "particleVariance${i}"[2]=${sum}
done
echo "special treat: oscillation" >> ${LOGFILE}
for (( i=0; i<totalParticleN; i++ )); do
	tmp="particleVariance${i}"
	tmpx=${tmp}"[2]"
	echo -n ${!tmpx}"  " >> ${LOGFILE}
done
echo " " >> ${LOGFILE}

##Phase 4: (quick sort)sort class oscillation(rather than variances as in Mk02)
##allocate new space for sorting
declare -a toSort
declare -a sortIndex
for (( i=0; i < totalParticleN; i++ )); do
	#(( tmp="particleVariance${i}"[1] ))
	#(( toSort[i]=tmp ))
	tmp="particleVariance${i}"
	tmp=${tmp}"[2]"
	eval toSort[$i]=${!tmp}
	(( sortIndex[i]=i ))
done

echo "Original:" >> ${LOGFILE}
for (( i=0; i<totalParticleN;i++ )); do
	echo -n "${toSort[$i]}:${sortIndex[$i]}   " >> ${LOGFILE}
done
echo " " >> ${LOGFILE}

(( tmp=totalParticleN-1 ))
Qsort 0 ${tmp}

echo "Sorted:" >> ${LOGFILE}
for (( i=0; i<totalParticleN; i++ )); do
	echo -n "${toSort[$i]}:${sortIndex[$i]}   " >> ${LOGFILE}
done
echo " " >> ${LOGFILE}
echo "Check Point 9" >> ${LOGFILE}
##Phase 5: extract particle( class label and image name ) from input .star and write output file( say .dat )
#both rogue and prodent ones
#_rlnImageName #10 INC
#_rlnCoordinateX #11 CXC
#_rlnCoordinateY #12 CYC
#_rlnMicrographName #13 MNC
#_rlnClassNumber #20 CNC
#
#_rlnNormCorrection #21 NCC
#_rlnLogLikeliContribution #22 LLCC
#_rlnMaxValueProbDistribution #23 MVPDC
#_rlnNrOfSignificantSamples #24 NSSC
#
#rogue particles
#write header
echo " " >> RogueParticles.star
echo "data_images" >> RogueParticles.star
echo " " >> RogueParticles.star
echo "loop_" >> RogueParticles.star
echo "_rlnImageName #1" >> RogueParticles.star
echo "_rlnCoordinateX #2" >> RogueParticles.star
echo "_rlnCoordinateY #3" >> RogueParticles.star
echo "_rlnMicrographName #4" >> RogueParticles.star
echo "_rlnClassNumber #5" >> RogueParticles.star
echo "_rlnNormCorrection #6" >> RogueParticles.star
echo "_rlnLogLikeliContribution #7" >> RogueParticles.star
echo "_rlnMaxValueProbDistribution #8" >> RogueParticles.star
echo "_rlnNrOfSignificantSamples #9" >> RogueParticles.star
#extract rogue ones
echo "writing rogue..." >> ${LOGFILE}
for (( i=totalParticleN-1; i >= totalParticleN-EXTRACTN; i-- )); do # extract gven number of particles
	# _tmp=$( awk -v x=${_rowN} -v y=${_TARGETCOLUMN} '{if ( NR==x ) { print  $y} else {} }' < ${_tempPath} )
	tmpRow=${sortIndex[$i]} ##hazard here?
	(( tmpRow += HEADERL + 1 ))
	(( selectedFileIndex = fileNameIndex - 1 ))
	_tempPath=${fileNames[${selectedFileIndex}]}
	echo "rogue:  "${i}"-"${tmpRow}"; path: "${_tempPath} >> ${LOGFILE}
	awk -v x=${tmpRow} -v a=${INC} -v b=${CXC} -v c=${CYC} -v d=${MNC} -v e=${CNC} -v f=${NCC} -v g=${LLCC} -v h=${MVPDC} -v i=${NSSC} '{if ( NR==x ) { print  $a, " ", $b, " ", $c, "",  $d, " ",  $e, " ", $f, " ", $g, " ", $h, " ", $i } else {} }' < ${_tempPath} >> RogueParticles.star
done

echo "Check Point 10" >> ${LOGFILE}
##prudent ones
echo " " >> PrudentParticles.star
echo "data_images" >> PrudentParticles.star
echo " " >> PrudentParticles.star
echo "loop_" >> PrudentParticles.star
echo "_rlnImageName #1" >> PrudentParticles.star
echo "_rlnCoordinateX #2" >> PrudentParticles.star
echo "_rlnCoordinateY #3" >> PrudentParticles.star
echo "_rlnMicrographName #4" >> PrudentParticles.star
echo "_rlnClassNumber #5" >> PrudentParticles.star
echo "_rlnNormCorrection #6" >> PrudentParticles.star
echo "_rlnLogLikeliContribution #7" >> PrudentParticles.star
echo "_rlnMaxValueProbDistribution #8" >> PrudentParticles.star
echo "_rlnNrOfSignificantSamples #9" >> PrudentParticles.star
(( selectedFileIndex = fileNameIndex - 1 ))
_tempPath=${fileNames[${selectedFileIndex}]}
for (( j = 0; j<totalParticleN-EXTRACTN; j++ )); do
	tmpRow=${sortIndex[${j}]}
	(( tmpRow += HEADERL + 1 ))
	echo "prudent:  "${j}"-"${tmpRow}"; path: "${_tempPath} >> ${LOGFILE}
	awk -v x=${tmpRow} -v a=${INC} -v b=${CXC} -v c=${CYC} -v d=${MNC} -v e=${CNC} -v f=${NCC} -v g=${LLCC} -v h=${MVPDC} -v i=${NSSC} '{if ( NR==x ) { print  $a, " ", $b, " ", $c, "",  $d, " ",  $e, " ", $f, " ", $g, " ", $h, " ", $i } else {} }' < ${_tempPath} >> PrudentParticles.star
done
echo "Check Point 11" >> ${LOGFILE}


##Phase 6: additional analysis [deleted]
#phase 7 [deleted]
echo "Job Done!" >> ${LOGFILE}
