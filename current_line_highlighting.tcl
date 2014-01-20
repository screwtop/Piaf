# Highighting the current line


# Question: is it faster to iterate through and use "tag remove", or just delete the tag and start anew?
#	Well, my initial stab (which uses remove) takes 11 microseconds per iteration, so I think we don't need to worry!
# 	Indeed, you can remove all tags just with a single remove specifying the entire text ("1.0 end").  And it's no slower, and certainly simpler.

# TODO: merge with updating of current position display in status bar?

# Will this fail if there is no such tag?
.editor.text tag configure current_line -background $::current_line_background_colour

proc update_current_line_highlighting {} {
	.editor.text tag remove current_line 1.0 end
	.editor.text tag add current_line "insert linestart" "insert lineend + 1 char"
	# + 1 char to catch the newline so that the entire line is highlighted (especially important when the line is empty, because they would otherwise have no visible highlighting at all).
}

# How to play nicely with the selection tagging?  You can change the priorities:
.editor.text tag lower current_line sel
# Ah-ha: nice. :)

# See insert_mark_tracking.tcl for the event stuff for this.


