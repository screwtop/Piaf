# Components and functionality for Find panel

frame .search

pack [button .search.close -text "✖" -command toggle_find_panel] -side left; setTooltip .search.close "Close search bar"
pack [label .search.label -text "Find:"] -side left
pack [entry .search.entry -width 20 -textvariable ::search_term] -side left
pack [button .search.clear -text ⌧ -command {set ::search_term ""}] -side left; setTooltip .search.clear "Clear search field"
pack [button .search.next -text "Next \u2192" -command {find $::search_term}] -side left

# TODO: clear field button, prev/next buttons, found/not found status, maybe count of matches
# ...
pack [label .search.replacement_label -text "Replacement:"] -side left
pack [entry .search.replacement -width 20 -textvariable ::replacement_term] -side left
pack [button .search.replace_all -text "Replace All" -command {replace_all $::search_term $::replacement_term}] -side left


#bind .search.entry <Return> {.search.next flash; .search.next invoke}
# Nah, actually, the flashing is annoying and impedes the nice fast auto-repeat+highlight capability.
bind .search.entry <Return> {.search.next invoke}

# TODO: when the search text is changed (or perhaps only when it's cleared to start a new search), resume searching from the start of the buffer.


# Functionality and key bindings to toggle the search panel

set ::find_panel_enabled true

# TODO: restore to the correct location in the GUI when re-packed!

proc toggle_find_panel {} {
	if {!$::find_panel_enabled} {
		# Activate
		show_find_panel
		set ::find_panel_enabled true
		focus .search.entry
	} else {
		# Deactivate
		grid remove .search
		set ::find_panel_enabled false
		focus .editor.text
	}
}

toggle_find_panel

bind . <Control-f> toggle_find_panel

bind .editor.text <Control-f> {toggle_find_panel; break}

# Even here the flashing is a bit obtrusive.
#bind .search.entry <Key-Escape> {.search.close flash; .search.close invoke}
bind .search.entry <Key-Escape> {toggle_find_panel}



