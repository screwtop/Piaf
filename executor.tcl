# This is the client-side part of the executor for running chunks of editor text in an external interpreter.  Basically just a matter of setting up bindings to send chunks of code to the Executor process.


# TODO: have Piaf identify and store the file type for the current file, and use that to determine what interpreter would be appropriate.
# Also, how will we know what Tk appname "our" executor server has, if there are several running at once?  Can we somehow use the PID from the [exec]?
# Also, there's a bit of a race condition here - we don't know how long the server will take to start up, and we can't send it any commands until it's ready to go.  Maybe 100 ms delay?  500 ms?

# Start the executor server:
# How to indicate what appname it should use?  We'll need to know it!  Ah, pass it as a command-line arg:

# Maybe we could provider for having multiple ones open, somehow identified.
proc start_executor {args} {
	# TODO: only start if there's not one already running?
	if {[info exists ::executor_appname]} {error "Executor instance already running"}
	set ::executor_appname "Executor ([tk appname])"
	exec $::binary_path/executor_server_expect.tcl $::executor_appname >& /dev/null &
	# Tell Executor what interpreter to use:
	after 500 [list send $::executor_appname {start_interpreter tclsh}]
	# TODO: support other languages (perhaps based on the choice in the Language menu)
	# if {[lindex $args 0] == Tcl} {...}
}

# TODO: parameterise for executor instance identifier?
proc stop_executor {} {
	send $::executor_appname quit
	unset ::executor_appname
}

proc hide_executor {} {send $::executor_appname {wm withdraw .}}

proc show_executor {} {send $::executor_appname {wm deiconify .}}

#bind .editor.text <Control-Return> {send Executor {execute [get_current_line]}}
# Nope, that tries to call get_current_line on the Executor!

#bind .editor.text <Control-Return> [list send Executor [list execute [get_current_line]]]
# Nope, that evaluates [get_current_line] and stores the result in the bind action!

# Maybe a new proc?
proc executor_send {code} {send $::executor_appname [list execute $code]}

# Should this receive a language name (e.g. "Tcl") or an interpreter command name (e.g. "tclsh")?
proc executor_change_interpreter {language} {
	send $::executor_appname [list change_interpreter $language]
}

#bind .editor.text <Control-Return> {executor_send [get_current_line]; break}
# OK, that's looking good.
# Might be nice to advance one line too:
# If there's a selection active, send that instead of just the current line:
# TODO: maybe check if an executor is running and only bother doing this if so.
bind .editor.text <Control-Return> {
	if {![info exists ::executor_appname]} {return}
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

