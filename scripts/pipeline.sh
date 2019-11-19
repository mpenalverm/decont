#Download all the files specified in data/filenames 
#for url in $(cat data/urls)
#do
#	bash scripts/download.sh $url data
#done

wget -P data $(cat data/urls)

#Download the contaminants fasta file, and uncompress it
bash scripts/download.sh https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz res yes

# Index the contaminants file
bash scripts/index.sh res/contaminants.fasta res/contaminants_idx

# Merge the samples into a single file
for sid in $(ls data/*.fastq.gz | cut -d"-" -f1 | sed "s:data/::" | sort | uniq )
do
    bash scripts/merge_fastqs.sh data out/merged $sid
done

# TODO: run cutadapt for all merged files
mkdir -p log/cutadapt
mkdir -p out/trimmed
for sid in $(ls out/merged | sed "s:.fastq.gz::")
do
	if [ ! -f "out/trimmed/$sid.trimmed.fastq.gz" ]
	then
		cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed -o out/trimmed/$sid.trimmed.fastq.gz out/merged/$sid.fastq.gz > log/cutadapt/$sid.log
	else
		echo "File already exists"
	fi
done

#TODO: run STAR for all trimmed files
for fname in out/trimmed/*.fastq.gz
do
   # you will need to obtain the sample ID from the filename
	sid=$(echo $(basename $fname .trimmed.fastq.gz))
	if [ ! -e "out/star/$sid/" ]
	then
		mkdir -p out/star/$sid/
    		STAR --runThreadN 4 --genomeDir res/contaminants_idx --outReadsUnmapped Fastx --readFilesIn $fname --readFilesCommand zcat --outFileNamePrefix out/star/$sid/
	else
		echo "File already exists"
	fi
done 

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci

touch log/pipeline.log
for sid in $(ls out/trimmed | sed "s:.trimmed.fastq.gz::")
do
	echo >> log/pipeline.log
	echo $sid >> log/pipeline.log
        echo >> log/pipeline.log
	echo "CUTADAPT ANALYSIS" >> log/pipeline.log
	cat log/cutadapt/$sid.log | grep "^Reads with adapters" >> log/pipeline.log
	cat log/cutadapt/$sid.log | grep "^Total basepairs processed" >> log/pipeline.log
        echo >> log/pipeline.log
	echo "STAR ANALYSIS" >> log/pipeline.log
        cat out/star/$sid/Log.final.out | grep "Uniquely mapped reads %" >> log/pipeline.log
        cat out/star/$sid/Log.final.out | grep "% of reads mapped to multiple loci" >> log/pipeline.log
        cat out/star/$sid/Log.final.out | grep "% of reads mapped to too many loci" >> log/pipeline.log
done
