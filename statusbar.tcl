# Statusbar things:

# Want menubuttons for line endings, font fixed/proportional, wrap mode, insert/overstrike, font, font size, etc. would be nice.  Oh, display of the filename, perhaps...editing time, undo history length...

# TODO: suitable padding for these


pack [frame .statusbar] -fill x -expand 0


# Some of the displays will have to be refreshed periodically rather than event-driven, so this will come in handy:
proc every {ms body} {
	if 1 $body
	after $ms [list after idle [info level 0]]
}


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
label .statusbar.position -textvariable ::insert_position -relief sunken
pack .statusbar.position -side right
# TODO: figure out how to bind an event handler to changes to the insert mark.  You can do it with tags (.editor.text tag bind ...).
# Might be nice to format the line-column value for ease of interpretation, e.g. L12:C23 (for Line and Column).
# In the meantime, we'll use a scheduled approach:
every 50 {set ::insert_position "L[join [split [.editor.text index insert] .] {:C}]"}


# Status/last operation/action performed:
pack [label .statusbar.status -textvariable ::status -relief sunken] -side right


# Character/Word/Line count:

pack [label .statusbar.stats -textvariable ::size_status -relief sunken] -side right

proc update_size_status {} {
	set text [get_all]
	set chars [string length $text]
	set lines [llength [split $text "\n"]]
	set words [llength [lsearch -all -not [split $text " \t\n,.!?"] {}]]
	set ::size_status "${chars}C,${words}W,${lines}L"
}

every 1000 update_size_status



# Selection details:

pack [label .statusbar.selection -textvariable ::selection_status -relief sunken] -side right
set ::selection_status "sel:none"

bind .editor.text <<Selection>> {
#	puts stderr <<Selection>>
	# Selection might have changed to be no selection, so need to catch and perform a little extra logic here.
	set selection ""
	catch {set selection [get_selection]}
	if {$selection != ""} {
	#	puts stderr "<<$selection>>"
		# TODO: a sensible way to count the lines here.  Number of linebreaks sometimes doesn't make sense, but a selection that starts partway through...
		# Ah, the basic problem is that triple-clicking includes the linebreak in the selection.
#		puts stderr "chars:[string length $selection], lines:[expr {[llength [split $selection \"\n\"]] - 1}]"
		set ::selection_status "sel:[string length $selection]C,[llength [split $selection \"\n\"]]L"
	} else {
		set ::selection_status "sel:none"
	}
	unset selection
}

# Interestingly, the <<Selection>> event is triggered even if the actual selection range doesn't change - a pixel's mouse movement is enough.
# Also, a strange thing happens when using shift+cursor keys to select no range: it reports a selection of 1 char, not 0!  I think it's a weirdness in how the Tk text widget built-in selection stuff works.


# TODO: live counts of characters, lines and maybe words






