# This script should download the file specified in the first argument ($1), place it in the directory specified in the second argument, 
# and *optionally* uncompress the downloaded file with gunzip if the third argument contains the word "yes".
if [ ! -f "$2/$(basename $1)" ]
then
	wget -P $2 $1
	if [ "$3" == "yes" ]
	then
		gunzip -k $2/$(basename $1) 
	fi
else
	echo "File $1 already exists"
fi
