# This is the client-side part of the executor for running chunks of editor text in an external interpreter.  Basically just a matter of setting up bindings to send chunks of code to the Executor process.


# TODO: have Piaf identify and store the file type for the current file, and use that to determine what interpreter would be appropriate.
# Also, how will we know what Tk appname "our" executor server has, if there are several running at once?  Can we somehow use the PID from the [exec]?
# Also, there's a bit of a race condition here - we don't know how long the server will take to start up, and we can't send it any commands until it's ready to go.  Maybe 100 ms delay?  500 ms?

# Start the executor server:
# How to indicate what appname it should use?  We'll need to know it!  Ah, pass it as a command-line arg:
set ::executor_appname "Executor ([tk appname])"
exec $::binary_path/executor_server_expect.tcl $::executor_appname >& /dev/null &

#bind .editor.text <Control-Return> {send Executor {execute [get_current_line]}}
# Nope, that tries to call get_current_line on the Executor!

#bind .editor.text <Control-Return> [list send Executor [list execute [get_current_line]]]
# Nope, that evaluates [get_current_line] and stores the result in the bind action!

# Maybe a new proc?
proc executor_send {code} {send $::executor_appname [list execute $code]}

# Tell Executor what interpreter to use:
after 500 [list send $::executor_appname {start_interpreter tclsh}]
# TODO: support other languages (perhaps based on the choice in the Language menu)

#bind .editor.text <Control-Return> {executor_send [get_current_line]; break}
# OK, that's looking good.
# Might be nice to advance one line too:
# If there's a selection active, send that instead of just the current line:
bind .editor.text <Control-Return> {
	if {[.editor.text tag ranges sel] != ""} {
		executor_send [get_selection]
	} else {
		executor_send [get_current_line]
		# Advance one line:
		.editor.text mark set insert "[.editor.text index insert] + 1 line"
	}
	break	;# Override existing binding
}

# TODO: a nice refinement might be to identify blocks of code automatically (based on the language).

# TODO: have the executor process closed when exiting this Piaf instance.  Maybe that can be hooked into an event, so that it can be defined here (along with all the other executor stuff), rather than having to be added to the big [quit] procedure.

