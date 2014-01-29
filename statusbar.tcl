# Statusbar things:

# Want menubuttons for line endings, font fixed/proportional, wrap mode, insert/overstrike, font, font size, etc. would be nice.  Oh, display of the filename, perhaps...editing time, undo history length...

# TODO: suitable padding for these


frame .statusbar


# Some of the displays will have to be refreshed periodically rather than event-driven, so this will come in handy:
proc every {ms body} {
	if 1 $body
	after $ms [list after idle [info level 0]]
}
# However, for certain timers, it might be useful to be able to adjust the timing once the "every" cycle has begun (certainly while testing, anyway).  TODO: implement.


# menubutton or tk_optionMenu for these?  It'd be nice to show the current state on the menu button itself...
tk_optionMenu .statusbar.wrapping ::wrap_mode "No Wrap" "Char Wrap" "Word Wrap"
.statusbar.wrapping configure -font $::fixed_gui_font -width 10

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
pack [label .statusbar.filename -textvariable ::filename -font $::fixed_gui_font] -side left
setTooltip .statusbar.filename "Current filename"



# Live line-column display ("insert" mark) (including number of lines and characters in selection!)
label .statusbar.position -textvariable ::insert_position -relief sunken -font $::fixed_gui_font -width 12
pack .statusbar.position -side right
setTooltip .statusbar.position "Cursor position (Line:Column)"
# TODO: figure out how to bind an event handler to changes to the insert mark.  You can do it with tags (.editor.text tag bind ...).
# Might be nice to format the line-column value for ease of interpretation, e.g. L12:C23 (for Line and Column).
# In the meantime, we'll use a scheduled approach:
#every 50 {set ::insert_position "L[join [split [.editor.text index insert] .] {:C}]"}
# We're now generating our own virtual event for motion of the "insert" mark, so we can [bind] instead (see ??):
proc update_insert_mark_display {new_position} {set ::insert_position "L[join [split $new_position .] {:C}]"}
#bind .editor.text <<Motion>> {set ::insert_position "L[join [split %d .] {:C}]"}	;# Only bind in one place!

# Status/last operation/action performed:
pack [label .statusbar.status -textvariable ::status -relief sunken -font $::fixed_gui_font -width 15] -side right
setTooltip .statusbar.status "File status"

# Character/Word/Line count:

pack [label .statusbar.stats -textvariable ::size_status -relief sunken -font $::fixed_gui_font -width 24] -side right
setTooltip .statusbar.stats "Character, word, line count"

proc update_size_status {} {
	set text [get_all]
	set chars [string length $text]
	set lines [llength [split $text "\n"]]
	set words [llength [lsearch -all -not [split $text " \t\n,.!?"] {}]]
	set ::size_status "${chars}C,${words}W,${lines}L"
}

# TODO: replace with smarter approach using an external process for calculating the stats
# or at least have a setting for how frequently it updates
# Might be able to use ::blt::bgexec for this
# Should send a line of text at a time to ensure GUI responsiveness
every 1000 update_size_status



# Selection details:

pack [label .statusbar.selection -textvariable ::selection_status -relief sunken -font $::fixed_gui_font -width 18] -side right
setTooltip .statusbar.selection "Selection range (chars, lines)"
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
		set ::selection_status "sel:[string length $selection]C,[llength [split $selection \n]]L"
	} else {
		set ::selection_status "sel:none"
	}
	unset selection
}

# Interestingly, the <<Selection>> event is triggered even if the actual selection range doesn't change - a pixel's mouse movement is enough.
# Also, a strange thing happens when using shift+cursor keys to select no range: it reports a selection of 1 char, not 0!  I think it's a weirdness in how the Tk text widget built-in selection stuff works.


