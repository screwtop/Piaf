all: wordcount

wordcount.c: wordcount.l
	flex --read --interactive --outfile=wordcount.c wordcount.l

wordcount: wordcount.c
	gcc -o wordcount wordcount.c -lfl
