# A simple command console window.
# Could imagine wanting file management, text editing in here alone!
# Would be nicer if we could just have tclsh + rlwrap in a terminal like we get when starting it up manually.
# Should also be possible to show/hide.

toplevel .console
pack [entry .console.entry -textvar command] -fill x -side top
bind .console.entry <Key-Return> {execute %W}
pack [text .console.output -wrap word] -fill both -expand 1
proc execute {w} {
	global command
	.console.output insert end "% $command\n"
	catch {uplevel #0 eval $command} res
	.console.output insert end $res\n
	set command ""
}
#eval pack [winfo children .] -fill both -expand 1
focus .console.entry

# Hmm, needs a history!
# Also, stdout/stderr are a bit weird.

wm withdraw .console	;# Hidden by default
wm protocol .console WM_DELETE_WINDOW {wm withdraw .console}	;# Hide rather than close when "closed".

