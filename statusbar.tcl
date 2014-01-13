# Statusbar things:

# Want menubuttons for line endings, font fixed/proportional, wrap mode, insert/overstrike, font, font size, etc. would be nice.  Oh, display of the filename, perhaps...editing time, undo history length...


pack [frame .statusbar] -fill x -expand 0

# menubutton or tk_optionMenu for these?  It'd be nice to show the current state on the menu button itself...
tk_optionMenu .statusbar.wrapping ::wrap_mode "No Wrap" "Char Wrap" "Word Wrap"
# Tricky args here because of how traces are called:
# TODO: deuglify: should just be a map call or something.
proc set_wrap_mode {name1 name2 op} {
#	puts "$name1 $name2 $op"
	set mode none
	switch $::wrap_mode {
		"No Wrap" {set mode none}
		"Char Wrap" {set mode char}
		"Word Wrap" {set mode word}
	}
	.editor.text configure -wrap $mode
}
trace variable ::wrap_mode w set_wrap_mode
pack .statusbar.wrapping -side left



# Filename display:
pack [label .statusbar.filename -textvariable ::filename] -side left



# Live line-column display ("insert" mark) (including number of lines and characters in selection!)
label .statusbar.position -textvariable ::insert_position
pack .statusbar.position -side right
# TODO: figure out how to bind an event handler to changes to the insert mark.  You can do it with tags (.editor.text tag bind ...).
# Might be nice to format the line-column value for ease of interpretation, e.g. L12:C23 (for Line and Column).
set ::insert_position "R[join [split [.editor.text index insert] .] {:C}]"


# Status/last operation/action performed:
pack [label .statusbar.status -textvariable ::status] -side right

# TODO: live counts of characters, lines and maybe words


