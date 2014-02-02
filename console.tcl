# A simple command console window.
# Could imagine wanting file management, text editing in here alone!  At least a command history.
# Would be nicer if we could just have tclsh + rlwrap in a terminal like we get when starting it up manually.
# Should also be possible to show/hide.
# TODO: make it work with commands containing quoted/braced spaces!

set ::console_history_index 0

toplevel .console
wm title .console "[tk appname] console"
pack [entry .console.entry -textvar command -font $::font] -fill x -side top
bind .console.entry <Key-Return> {execute %W}
bind .console.entry <Key-Up> {
	incr ::console_history_index
	if {$::console_history_index > [llength $::console_history]} {set ::console_history_index [llength $::console_history]}
	set command [lindex $::console_history end-$::console_history_index]
	.console.entry icursor end
}
bind .console.entry <Key-Down> {
	incr ::console_history_index -1
	if {$::console_history_index < 0} {
		set ::console_history_index -1
		set command ""
	} else {
		set command [lindex $::console_history end-$::console_history_index]
	}
	.console.entry icursor end
}
pack [text .console.output -wrap word] -fill both -expand 1
.console.output configure -font $::font -background black -foreground #00ff00

set ::console_history [list]

proc execute {w} {
	global command
	if {$command == ""} {return}
	.console.output insert end "% $command\n"	;# TODO: tag showing it's user input
	catch {uplevel 1 $command} result
	.console.output insert end $result\n
	.console.output see end
	lappend ::console_history $command
	set ::console_history_index -1
	set command ""
	unset result
}

focus .console.entry

# Hmm, needs a history!
# Also, stdout/stderr are a bit weird.  Use "return" instead of "puts' in your console commands.

wm withdraw .console	;# Hidden by default
wm protocol .console WM_DELETE_WINDOW {wm withdraw .console}	;# Hide rather than close when "closed".

