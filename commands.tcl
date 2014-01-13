# Internal commands for my simple Tcl/Tk text editor
# Many of these will have menu items and keyboard shortcuts.  Oh, does Tk allow you to define a keyboard shortcut as part of the menu item?  Would be especially nice if that were done in a platform-independent way.
# I could also imagine these being used in scripts, either for remotely controlling the application, or just for automating actions within it.

proc select_all {} {.editor.text tag add sel 0.0 end}
proc get_selection {} {.editor.text get sel.first sel.last}	;# TODO: what if there are multiple selection ranges?  It can happen!
proc get_all {} {.editor.text get 0.0 end}	;# TODO: does this add a trailing linebreak?!

proc copy {} {clipboard clear; clipboard append [.editor.text get sel.first sel.last]}
proc paste {} {.editor.text insert insert [clipboard get]}	;# TODO: if a selection was active when pasting, should the newly pasted region become the selection range?

# Delete selected text:
proc delete {} {.editor.text delete sel.first sel.last}

# Erase all text in document:
proc clear {} {.editor.text delete 0.0 end}

proc cut {} {copy; delete}

proc undo {} {.editor.text edit undo}
proc redo {} {.editor.text edit redo}


# File operations...

# Because I'm a database fanatic, let's record file operations in a log:
# How to determine hostname?  [info hostname] generally just returns the host name portion, not the domain name.  $env(??)?
proc log_file_operation {filename operation} {
	global env
	set sql "insert into File_Log (Hostname, Username, Filename, Date_Performed, Operation) values ('[info hostname]', '$env(USER)', '$filename', current_timestamp, '$operation');"
#	puts stderr $sql
	::piaf::database eval $sql
	# TODO: check for success?
}


# A "file-slurp" function (read the entire contents of a file into a variable) abstraction:
proc slurp {filename} {
	set file_handle [open $filename r]
	set file_data [read $file_handle]
	close $file_handle
	return $file_data
}


# Or just plain "new"?
proc new {} {
	# TODO: check for unsaved changes?
	set ::filename ""	;# OR unsert ::filename?
	clear
	.editor.text edit modified false
	set ::status "New"
}

# Create a new document and set the filename:
# Maybe do away with new and just allow calling "new_file {}"?  They're otherwise just the same.  Or make the "filename" arg optional?
proc new_file {filename} {
	# Should this actually create/touch the file, or just set the filename?
	set ::filename $filename
	clear
	.editor.text edit modified false
	set ::status "New file"
}

# Open a file, replacing all current text:
# Don't override built-in [open]!
proc open_file {filename} {
#	log_file_operation $filename OPEN	;# Don't bother - just log centrally in "load" proc.
	if {$filename != ""} {
		# Remember filename globally
		set ::filename $filename
		# Set the window title as well (perhaps just the file's basename or the abbreviated filename?):
		wm title . "Piaf: [file tail $::filename]"
		clear
		load $filename
		.editor.text mark set insert 0.0
	} else {
		set ::status "Cancelled/No file specified"
	}
}

# Load text from file (at current insert mark, keeping other text? I do plan to have an "Insert file into current buffer" command as well.):
proc load {filename} {
	set ::status "Loading…"
	if {[catch {.editor.text insert insert [slurp $filename]} message]} {
		set ::status $message
		unset message
		return
	}
	.editor.text edit modified false	;# Reset modification flag
	log_file_operation $filename LOAD
	set ::status "File loaded"
}

# Reload/refresh from file:
proc reload {} {
	set ::status "Reloading…"
	if {$::filename != ""} {
		clear
		load $::filename
	}
	set ::status "Reloaded"
}


# Prompt user for file to open:
proc prompt_open_file {} {
	# TODO: handle filename being empty?  Or do that in open_file itself?
	open_file [tk_getOpenFile -title "Open text file for editing"]	;# -initialdir -initialfile -message "Select text file to open for editing"
}



# Save to already known filename
proc save {} {
	save_to $::filename	;# Re-use save_to proc
}

# Save to specific filename and remember it:
proc save_as {filename} {
	set ::filename $filename
	save
}

# Save to specific file but without changing ::filename (basically, save a copy)
# TODO: some error handling?
# Haha, my first test of this found a problem: attempting to write to an existing FIFO!  TODO: remedy.
proc save_to {filename} {
	if {$filename == ""} {
		set ::status "Cancelled/No file specified"
		return
	}
	set ::status "Saving…"
	log_file_operation $filename SAVE
	# Make backup/versioned copy always as well?
	# file stat /tmp/test.txt file_stats
	# file copy SOURCE TARGET
	set file [open $filename w]
	puts -nonewline $file [get_all]	;# Hmm, even with -nonewline we're ending up with extra creeping newlines appearing each time we save (or open?).  TODO: fix.
	close $file
	.editor.text edit modified false	;# Reset modification flag
	set ::status "File saved"
}


# I think we need "Save As" and "Save To" prompted wrappers here too.
# Prompt user for filename to save as:
proc prompt_save_generic {} {
	# TODO: handle filename being empty?  Or do that in 
	tk_getSaveFile -title "Filename to save as" -confirmoverwrite true	;# -initialdir -initialfile
}

proc prompt_save_as {} {save_as [prompt_save_generic]}	;# Save here, and remember the filename

proc prompt_save_to {} {save_to [prompt_save_generic]}	;# Save a copy here, but retain the current filename


# Isn't this basically the same as "new"?
proc close_file {} {
	# TODO: check for unsaved changes
	set ::filename ""	;# or unset ::filename?
	clear
	.editor.text edit modified false
	set ::status "File closed"
}



# TODO: command: jump to line x.
proc jump_to_line {line_number} {
}


# TODO: support for opening a file from a URL?  Maybe callout to wget/curl?

# Take selected text and open as URL in browser:
proc open_selection_in_browser {} {
	set ::status "Opening browser…"
	exec $::browser [string trim [get_selection]] 2> /dev/null &
	set ::status "Ready"
}

proc search_web_for_selection {} {
	# TODO: encode search terms for URL:
	set ::status "Opening browser…"
	exec $::browser "https://www.google.co.nz/search?q=[get_selection]" 2> /dev/null &
	set ::status "Ready"
}

# Wikipedia lookup:
proc search_wikipedia_for_selection {} {
	set ::status "Opening browser___"
	exec $::browser "http://en.wikipedia.org/wiki/[get_selection]" 2> /dev/null &
	set ::status "Ready"
}

# Wiktionary lookup:
proc search_wiktionary_for_selection {} {
	set ::status "Opening browser___"
	exec $::browser "http://en.wiktionary.org/wiki/[get_selection]" 2> /dev/null &
	set ::status "Ready"
}



# For simple text filters that require no additional arguments:
proc transform {function text} {::piaf::transform::$function $text}
# TODO: could maybe generalise to support extra args?  What was the Tcl convention for that again?  "args"?

# Apply a text transformation function to the selected text, replacing it in the editor.
# NOTE: currently does not handle the case of the "sel" mark having multiple ranges!
# Also, somehow handle invoking this with no selection active.  Could maybe just do nothing if there's no selection...but this function might also be used for generators, in which case there might not be a selection.
# TODO: currently this plays strangely with undo: the deletion counts as an extra operation.  Can we exempt that somehow?
proc transform_selection {function} {
	set ::status "Transforming…"
	set initial_insert_mark [.editor.text index insert]	;# Remember initial insert point
	set text [get_selection]	;# Copy original text
	set transformed_text [$function $text]
	.editor.text delete sel.first sel.last	;# Remove the selected text (to be replaced with transformed)
	set sel_start [.editor.text index insert]	;# Note start of new sel range
	.editor.text insert insert $transformed_text	;# Insert the transformed text
	set sel_end [.editor.text index insert]	;# Note end of new sel range
	.editor.text tag add sel $sel_start $sel_end	;# Restore selection range to the new text.
	.editor.text mark set insert $initial_insert_mark	;# Might be wrong? Esp. if sel changes size?
	unset text
	unset transformed_text
	set ::status "Transformed"
}

# Might it make sense to have simple wrappers for transformation functions for use in scripts?
proc rot13 {} {transform_selection ::piaf::transform::rot13}


# For generator functions, it's much simpler:
proc insert {text} {.editor.text insert insert $text}

proc insert_ascii {} {insert [::piaf::generate::ascii]}


proc quit {} {
	set ::status "Exiting…"
	# TODO: Check for unsaved changes (and/or auto-save recovery files)
	if {![.editor.text edit modified]} {
		# Maybe prompt for user certainty regardless
		# Log QUIT operation as well?
		::piaf::database close
		exit
	} else {
		set ::status "Unsaved changes!"
		# TODO: prompt or whatever
	}
}




