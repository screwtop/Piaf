# I've been thinking it would be much more elegant to generate virtual events centrally for movement of the "insert" mark.
# It's a shame there doesn't appear to be an event for this already...makes me wonder if I'm just not looking hard enough.
# This code is used by the statusbar cursor position display, and also the code for highlighting the current line.


set ::prev_insert_mark [.editor.text index insert]	;# initialise

proc detect_insert_mark_motion {} {
	set ::curr_insert_mark [.editor.text index insert]
	if {$::curr_insert_mark != $::prev_insert_mark} {
		# Changed!
		event generate .editor.text <<Motion>> -data $::curr_insert_mark
		set ::prev_insert_mark $::curr_insert_mark
		unset ::curr_insert_mark
	}
}

every 10 detect_insert_mark_motion

# Test:
#bind .editor.text <<Motion>> {puts "moved to %d"}

# Remember, only bind once!  Don't want to override existing bindings.
bind .editor.text <<Motion>> {update_current_line_highlighting; update_insert_mark_display %d}

# Ping it once at startup to initialise the display:
#event generate .editor.text <<Motion>> -data 1.0
# How come that doesn't work?
#	Indeed, how comes it doesn't work but doesn't cause an error on Marvin, but fails at startup on Zaphod?  Race condition with opening GUI maybe?

