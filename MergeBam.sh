#!/bin/bash
#PBS -l nodes=1:ppn=1
#PBS -l mem=50gb
#PBS -l walltime=100:00:00


if [[ $1 == "help" ]]; then
	echo "Add readgroup to bam and merge bam"
        echo "Usage: qsub $0 or bash $0 (Use highmem in qsub, 30G)"
	exit 1
fi

dir=.                      ##dir of bam files, do not include last /
sample=EG4                 ##sample of bam files, HEG4, EG4 or A123, A119
sufix=clean.EG4_CLEAN.bam  ##sufix of bam files, like FC52_7.MSU7_BWA.bam, FC52_7 will be library
cd $PBS_O_WORKDIR

for i in `ls $dir/*.$sufix | sed 's/@//'`
do
   echo "Step1: Add readgroup to bam"
   echo "Bam files:" $i
   lib="`basename $i .$sufix`"
   echo "Library:" $lib
   (( j += 1 ))
   jn="`printf "%02d" $j`"
   echo "Rank:" $jn
   if [ ! -e $i.group.bam ]; then
   java -Xmx30G -jar /opt/picard/1.81/AddOrReplaceReadGroups.jar VALIDATION_STRINGENCY=LENIENT I=$i O=$i.group.bam ID=$j LB=$lib PL=illumina PU=$jn SM=$sample
   /usr/local/bin/samtools index $i.group.bam 
   fi
done
      
echo "Step2: Merge bam"      
input=""

for bam in `ls $dir/*.$sufix.group.bam`
    do
        echo $bam
        input=$input" INPUT=$bam"    
    done
echo $input
if [ ! -e HEG4.MSU7_BWA.ALL.bam ]; then
java -Xmx30G -jar /opt/picard/1.81/MergeSamFiles.jar VALIDATION_STRINGENCY=LENIENT $input USE_THREADING=true OUTPUT=$sample.MSU7_BWA.ALL.bam
/usr/local/bin/samtools index $sample.MSU7_BWA.ALL.bam
fi

echo "Clean temp files"
rm *.group.bam*

echo "All Done"


