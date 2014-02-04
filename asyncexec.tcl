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

# A more complex example, using input, output, and stderr:
if 0 {
#...
lassign [asyncexec date send_input_line handle_output handle_error]
# Any need to close the other channels explictly?
}
##


proc asyncexec {command inputhandler outputhandler errorhandler} {
	# More advanced version with separate stdout and stderr. Requires Tcl 8.6.  TODO: figure how how/when to close all these channels!  Also, I think this should 
if 0 {
	# Separate stdout and stderr:
	lassign [chan pipe] stdin_output stdin_input
	lassign [chan pipe] stdout_output stdout_input
	lassign [chan pipe] stderr_output stderr_input

	set pids [exec $command <@ $stdin_output >@ $stdout_input 2>@ $stderr_input &]

	chan configure $stdout_output -blocking 0 -buffering line
	chan configure $stderr_output -blocking 0 -buffering line
	chan configure $stdin_input -blocking 0 -buffering line

	if {$inputhandler  != ""} {chan event $stdin_input   writable [list $inputhandler  $stdin_input]}
	if {$outputhandler != ""} {chan event $stdout_output readable [list $outputhandler $stdout_output]}
	if {$errorhandler  != ""} {chan event $stderr_output readable [list $errorhandler  $stderr_output]}

	return [list $stdin_input $stdout_output $stderr_output]	
}	

	# Original, single-channel version:
	set channel_id [open "|$command 2>@1" RDWR]
	chan configure $channel_id -blocking 0 -buffering line
	# TODO: should these use [after 0] and [after idle] to ensure minimal encroachment on responsiveness of the main thread?
	# By convention, the callbacks must accept a channel ID as an argument:
	if {$outputhandler != ""} {chan event $channel_id readable [list $outputhandler $channel_id]}
	if {$inputhandler  != ""} {chan event $channel_id writable [list $inputhandler  $channel_id]}
	# I'm not exactly sure if I intended errorhandler to be for stderr or for specific error events somehow.

	# What's more useful for the caller to know: the PID or the channel name?  Probably the channel name, as you can map from that to the PID if necessary using [pid $chan]
	return $channel_id
}


