# This script should index the genome file specified in the first argument,
# creating the index in a directory specified by the second argument.

# The STAR command is provided for you. You should replace the parts surrounded by "<>" and uncomment it.

if [ ! -f "$2/SAindex" ]
then
	mkdir -p $2
	STAR --runThreadN 4 --runMode genomeGenerate --genomeDir $2 --genomeFastaFiles $1 --genomeSAindexNbases 9
else
	echo "Index already done"
fi
