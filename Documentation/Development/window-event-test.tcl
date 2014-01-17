#!/usr/bin/wish

# Some testing of window events in Tk (~xev in Tcl/Tk)

# What events to test:
set events {Map Unmap Create Destroy Expose Configure Activate Deactivate Visibility Enter Leave FocusIn FocusOut}
# There's also ButtonPress ButtonRelease Motion MouseWheel KeyPress KeyRelease

# NOTE: when there are multiple events bound to a "window", only one will apply, unless they have different binding tags!  So in setup_bind_test, we bind to a special tag name, instead of the window name.  Those special tags are then also associated with the "." window name (which is actually a binding tag name as well) using [bindtags].
proc setup_bind_test {event} {
	bind $event <$event> "puts stderr \"<$event> geometry=\[wm geometry .\]\""
	bindtags . [concat [bindtags .] $event]	;# Append the binding tag for the new event to the toplevel window.
}

foreach event $events {
	setup_bind_test $event
}

puts stderr "\[bind .\] = [bind .]"
puts stderr "\[bindtags .\] = [bindtags .]"

wm title . TEST
puts -nonewline stderr "Sleeping for 5 seconds..."
exec sleep 5
puts stderr "Done!"
wm title . Boo!

# Let's also try http://wiki.tcl.tk/2224
#package require Expect	;# (or TclX) for [fork]
proc daemonise {} {
	close stdin
	close stdout
	close stderr
	puts stderr "forking; new PID = [fork]"
	signal ignore  SIGHUP
	signal unblock {QUIT TERM}
	signal trap    {QUIT TERM} shutdown
	puts stderr "What now...?!"
}

