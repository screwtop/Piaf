# Key and other event bindings for Piaf
# Longer term it might make sense to store functions along with their menus and key bindings in the database.


bind .editor.text <3> "tk_popup .popup_menu %X %Y"


# Interestingly, bindings for Ctrl-C and Ctrl-V are already there!
# Ctrl-F I'd like to be Find, but it's already move forward one character.
# Ctrl-A likewise to move to start of line.
# Should these be bound to the toplevel (.) or the editor text widget?
bind . <Control-a> select_all	;# TODO: remove built-in binding for text widget (go to start of line)
# These are already bound in the text widget:
#bind .editor.text <Control-x> cut
#bind .editor.text <Control-c> copy
#bind .editor.text <Control-v> paste

bind . <Control-z> undo
bind . <Control-f> find

bind . <Control-o> prompt_open_file
bind . <Control-s> save

bind . <Control-w> close

