#!/usr/bin/env wish

# A background process for running Frink

# We need Tk for IPC, but we have no GUI.  But maybe it would be nice to have a systray icon/menu thing.  TODO.
wm withdraw .

# On startup, check that there isn't already a frinkserver process running that we could attach to.  A JVM for every Piaf instance would get stupidly memory-hungry!
if {[lsearch [winfo interps] "frinkserver"] >= 0} {
	puts stderr "Frink server already running (process ID [send frinkserver pid]).  This one will now exit."
	exit
}
tk appname frinkserver



# Start Frink process (it's Java so it takes like 10 seconds):

package require Expect
set timeout 3
spawn java -cp /usr/share/java/frink.jar frink.parser.Frink
log_user 0
match_max 100000
expect {
	-re "Frink - Copyright .* Alan Eliasen, eliasen@mindspring.com.\r\n" {}
	eof {puts stderr "Java exited abnormally.  Perhaps check your virtual memory limit (try 'ulimit -v 4194304')."; exit}
}

# TODO: communicate with Piaf to indicate when ready?  Ah, but there might be multiple instances, and we wouldn't know what they were called.  But we could use [winfo interps] to find all (likely) Piaf instances and tell them that the frinkserver has started up.

# Frink echoes back the command, which we can just discard.
# Frink does not prompt for more input by default, which could make determining the end of its output rather impossible.  We can't use exp_continue, cos we won't know when to stop.  We can't use a loop.  Hmm.
# Ah, we can make our own prompt.  Have it print["frink>"] after evaluating our expression, so we can easily detect when it's done.
# Also, I think Frink/Java does some crazy things with terminal settings - I see lots of weirdo control characters in the output from `autoexpect`.  No idea what to do about those, really.  Does TERM make a difference?  Also, Frink echoes back the characters as you type them, and ALSO echoes back the entire line again when you execute it. (or does it?  It seems fairly normal now on my work machine...)
# TODO: errors might require special handling (they're usually multi-line Java stack-traces)...or just return everything and let the user figure it out.

proc frink {expression} {
	set code "println\[$expression\]; print\[\"frink>\"\]"
	exp_send -- $code	;# NOTE: no newline
	expect -exact $code	;# Ignore the text we just sent being echoed back by Frink
	exp_send -- "\r"	;# Tell Frink to evaluate the line
	expect -re "\r\n(.*)\r\nfrink>" {
			# Return the important part of the output:
			return [regsub -all "\[\r\n\]+" $expect_out(1,string) "\n"]
	}
}

# Remote queries can be done using Tk's [send] command (quick and dirty IPC).
puts "\nfrinkserver running. Send commands from another Tk process like so:"
puts "send frinkserver {frink {100000 furlongs/fortnight -> km/hour}}"
# or, indeed:
# proc frink {expression} {send frinkserver [list frink $expression]}
# frink gravity


# Once running, simple expressions only take a few milliseconds.

# TODO: graceful closey things?
proc quit {} {
	exp_close
	exp_wait
	exit
}



