# Key and other event bindings for Piaf
# Longer term it might make sense to store functions along with their menus and key bindings in the database.


bind .editor.text <3> "tk_popup .popup_menu %X %Y"


# Interestingly, bindings for Ctrl-C and Ctrl-V are already there!
# Ctrl-F I'd like to be Find, but it's already move forward one character.
# Ctrl-A likewise to move to start of line.
# Should these be bound to the toplevel (.) or the editor text widget?
bind . <Control-a> select_all	;# TODO: remove built-in binding for text widget (go to start of line)
bind . <Control-l> select_current_line
# These are already bound in the text widget:
#bind .editor.text <Control-x> cut
#bind .editor.text <Control-c> copy
#bind .editor.text <Control-v> paste

bind . <Control-z> undo
# Find bindings now in find_panel.tcl
#bind .editor.text <Control-f> break	;# Remove default text widget binding
#bind . <Control-f> find

bind .editor.text <Control-o> break	;# Remove default text widget binding
bind . <Control-o> prompt_open_file
bind . <Control-s> save
bind . <Control-S> prompt_save_as

bind . <Control-w> close_file
bind . <Control-q> quit

# Bindings for .editor.text <<Modified>> now in text_modification_tracking.tcl
#bind .editor.text <<Modified>> {puts stderr modified; set ::status Modified}
#bind .editor.text <<Modified>> {
##	puts stderr modified
#	if {[.editor.text edit modified]} {set ::status Modified}
#}
# TODO: Could possibly want to log the file modification event to the file log as well (the event is only triggered by the first modification).
# Interestingly (and kind of annoyingly), the act of setting the "modified" flag to false also triggers the <<Modified>> event!




