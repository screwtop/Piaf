# Our own convenience procedure for starting up a background asynchronous process.  Would be useful for things like spell-checking, word counting, lexical highlighting.  Probably wouldn't use it for 

# To use it, you'd need to define callback procs for input and/or output and/or error handling (some background processing would be read-only, some read-write), and pass those when calling asyncexec to set up the command pipeline.
# e.g. for a simple read-only background process:
if 0 {
proc handle_output {chan} {
 	gets $chan line
	puts stderr $line
	if {[chan eof $chan]} {close $chan}
}
asyncexec date {} handle_output {}
}
##


proc asyncexec {command inputhandler outputhandler errorhandler} {
	set channel_id [open "|$command" RDWR]
	chan configure $channel_id -blocking 0 -buffering line
	# TODO: should these use [after 0] and [after idle] to ensure minimal encroachment on responsiveness of the main thread?
	# By convention, the callbacks must accept a channel ID as an argument:
	if {$outputhandler != ""} {chan event $channel_id readable [list $outputhandler $channel_id]}
	if {$inputhandler  != ""} {chan event $channel_id writable [list $inputhandler  $channel_id]}
	# What's more useful for the caller to know: the PID or the channel name?  Probably the channel name, as you can map from that to the PID if necessary using [pid $chan]
	return $channel_id
}

