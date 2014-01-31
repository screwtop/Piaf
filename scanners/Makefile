all: null test Tcl wordcount

# NOTE: it's important for the flex scanners to be built for responsive interactive-style operation, even when in a pipeline, hence --interactive --read.
% : %.l
	flex --outfile=$@.c --interactive --read $<
	gcc -o $@ $@.c -lfl

