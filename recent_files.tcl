# List of recently-opened files.
# Just as a separate window for now (not a biggie if using a decent window manager).

toplevel .recent
wm title .recent "Recent Files"
listbox .recent.list -listvariable ::recent_files
pack .recent.list -expand true -fill both
# TODO: scrollbar?  Or assume the list will generally be small and that the mousewheel can be used instead?

proc show_recent_files {} {wm deiconify .recent}
proc hide_recent_files {} {wm withdraw .recent}

# Make the window immune to normal closing (hide instead):
wm protocol .recent WM_DELETE_WINDOW {hide_recent_files}


# Bindings for triggering loading the specified file:
bind .recent.list <Key-Return> {open_file [.recent.list get active]}
bind .recent.list <Double-ButtonPress-1> {open_file [.recent.list get active]}

# Repopulate the list from the database (takes ~1.5 ms):
proc refresh_recent_file_list {} {
	set ::recent_files [list]
	::piaf::database eval {select Filename, Timestamp from Recent_Files limit 10} {
		lappend ::recent_files $Filename
		# TODO: tooltip for Timestamp?  Can we address each item in the list as a separate window?
	}
}

# Populate it once at loading time:
refresh_recent_file_list

# TODO: refresh the list every so often, as background-y as possibly.
# every 5000 refresh_recent_file_list
# Maybe also refresh it every time a file is opened.

