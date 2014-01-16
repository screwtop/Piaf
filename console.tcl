# A simple command console window.
# Could imagine wanting file management, text editing in here alone!  At least a command history.
# Would be nicer if we could just have tclsh + rlwrap in a terminal like we get when starting it up manually.
# Should also be possible to show/hide.
# TODO: make it work with commands containing quoted/braced spaces!

toplevel .console
wm title .console "[tk appname] console"
pack [entry .console.entry -textvar command -font $::font] -fill x -side top
bind .console.entry <Key-Return> {execute %W}
bind .console.entry <Key-Up> {
	set command [lindex $::console_history end]
	# TODO: proper navigation of history, not just last command!
	.console.entry icursor end
}
pack [text .console.output -wrap word] -fill both -expand 1
.console.output configure -font $::font -background black -foreground green

set ::console_history [list]

proc execute {w} {
	global command
	.console.output insert end "% $command\n"	;# TODO: tag showing it's user input
	catch {uplevel 1 $command} result
	.console.output insert end $result\n
	.console.output see end
	lappend ::console_history $command
	set command ""
	unset result
}

focus .console.entry

# Hmm, needs a history!
# Also, stdout/stderr are a bit weird.  Use "return" instead of "puts' in your console commands.

wm withdraw .console	;# Hidden by default
wm protocol .console WM_DELETE_WINDOW {wm withdraw .console}	;# Hide rather than close when "closed".









