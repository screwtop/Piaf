# Internal commands for my simple Tcl/Tk text editor
# Many of these will have menu items and keyboard shortcuts.  Oh, does Tk allow you to define a keyboard shortcut as part of the menu item?  Would be especially nice if that were done in a platform-independent way.
# I could also imagine these being used in scripts, either for remotely controlling the application, or just for automating actions within it.

# TODO: maybe clear/reset the undo history on commands like "new" and "open_file".

proc about {} {
	puts stderr $::piaf::about_string
	tk_messageBox -title About -message $::piaf::about_string -icon info
}

proc select_all {} {.editor.text tag add sel 0.0 end}
proc select_current_line {} {.editor.text tag add sel "insert linestart" "insert lineend"}
proc select_none {} {
	foreach {start_index end_index} [.editor.text tag ranges sel] {
		.editor.text tag remove sel $start_index $end_index
	}
}

proc get_selection {} {.editor.text get sel.first sel.last}	;# TODO: what if there are multiple selection ranges?  It can happen!
proc get_all {} {.editor.text get 0.0 end}	;# TODO: does this add a trailing linebreak?!
proc get_current_line {} {.editor.text get "insert linestart" "insert lineend"}
proc get_line {line_number} {.editor.text get "$line_number.0 linestart" "$line_number.0 lineend"}

proc copy {} {clipboard clear; clipboard append [.editor.text get sel.first sel.last]}
proc paste {} {.editor.text insert insert [clipboard get]}	;# TODO: if a selection was active when pasting, should the newly pasted region become the selection range?

# Delete selected text:
proc delete {} {.editor.text delete sel.first sel.last}

# Erase all text in document:
proc clear {} {.editor.text delete 1.0 end; puts stderr "** clear done"; flush stderr}

proc cut {} {copy; delete}

proc undo {} {.editor.text edit undo}
proc redo {} {.editor.text edit redo}


# File operations...

# Because I'm a database fanatic, let's record file operations in a log:
# How to determine hostname?  [info hostname] generally just returns the host name portion, not the domain name.  $env(??)?
proc log_file_operation {filename operation} {
	global env
	if !$::use_database return
	set sql "insert into File_Log (Hostname, Username, Filename, Date_Performed, Operation) values ('[info hostname]', '$env(USER)', '[string map {' ''} $filename]', current_timestamp, '$operation');"
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


# We don't want to allow the user to lose work accidentally, so we track whether the current buffer is unsaved in the variable ::unsaved.
# Any time we want to reset that, we also need to change the "modified" flag in the text widget itself.
# We could possibly also ensure consistency by putting a variable trace on ::unsaved, yes?  Ah, but "load_file" needs to be able to restore the old value of ::unsaved without triggering <<Modified>>, so no!

proc set_unsaved {args} {
	# No arg -> true
	set ::unsaved [expr {[llength $args] == 0 || [lindex $args 0]}]
	.editor.text edit modified $::unsaved
}


# Discard old editor buffer and create a new one (optionally under the specified filename).
# TODO: call this if the file requested on the command line does not exist.
proc new {args} {
	puts stderr "** check unsaved"; flush stderr
	check_for_unsaved_changes
	puts stderr "** unlock"; flush stderr
	unlock $::filename
	if {[llength $args] > 0} {
		set ::filename [lindex $args 0]
	} else {
		set ::filename ""	;# OR unset ::filename?
	}
	puts stderr "** clear"; flush stderr
	clear
	puts stderr "** update_text_extent_display"; flush stderr
	update_text_extent_display
	puts stderr "** set_unsaved false"; flush stderr
	set_unsaved false
	puts stderr "** set ::status"; flush stderr
	set ::status "New"
}


# Open a file, replacing all current text:
# This is named open_file so as not to override Tcl's built-in [open]!
proc open_file {filename} {
#	log_file_operation $filename OPEN	;# Don't bother - just log centrally in "load_file" proc.
	if {$filename != ""} {
		check_for_unsaved_changes
		unlock $::filename
		if {![lock $filename]} {error "open_file $filename: file is locked ([get_lock_data $filename])"}
		# Remember filename globally
		set ::filename $filename
		# Set the window title as well (perhaps just the file's basename or the abbreviated filename?):
		# Now handled by a variable trace on ::filename.
	#	wm title . "Piaf: [file tail $::filename]"
		clear
		load_file $filename
		set_unsaved false
		.editor.text mark set insert 0.0
		focus .editor.text
	} else {
		set ::status "Cancelled/No file specified"
	}
}

# Carry out the lower-level function of actually loading the text from file; essentially "load text from filename into buffer".  This doesn't clear the existing text, so that it can serve as the basis for plain old "Open" as well as an "Insert file into current buffer".  It therefore doesn't need to trigger <<Modified>>.  Nor does it need to adjust any locks.
# Oops, don't call this "load" - that's a rather important existing built-in command for loading C libraries/extensions!
proc load_file {filename} {
	set ::status "Loading…"
	# The editor insert command below will reset the modification flag on the text, which we don't necessarily want, so store the current value so we can restore it afterwards:
	set current_unsaved_value $::unsaved
	if {[catch {.editor.text insert insert [slurp $filename]} message]} {
		set ::status $message
		unset message
		return
	}
	set ::unsaved $current_unsaved_value
	# Um, if "load_file" is being called from "insert_file", we want ::unsaved to be true!  However, if it's being called from open_file, it should be false.  So, don't set it here!  Likewise for the <<Modified>> virtual event.
	log_file_operation [file normalize $filename] LOAD
	update_text_extent_display
	refresh_recent_file_list
	set ::status "File loaded"
	unset current_unsaved_value
}

# The only difference when doing an "Insert" from a file is that it'd be nice to be left with the new text highlighted for ease of recognition, further transformation, etc.
proc insert_file {filename} {
	# Take a note of the current insert mark position (this will be the start of the inserted text range):
	set ::inserted_text_start_index [.editor.text index insert]
	load_file $filename
	set ::inserted_text_end_index [.editor.text index insert]	;# Where are we now?
	.editor.text tag add sel $::inserted_text_start_index $::inserted_text_end_index	;# Mark the new text as the selection range (TODO: only if the load was invoked by the "insert" command.
	set_unsaved true
	.editor.text mark set insert 0.0
	focus .editor.text

	unset ::inserted_text_start_index
	unset ::inserted_text_end_index
}

# Reload/refresh from file:
# TODO: could maybe double-check that we do indeed hold the lock for this file.
proc reload {} {
	set ::status "Reloading…"
	check_for_unsaved_changes
	if {$::filename != ""} {
		clear
		load_file $::filename
		set_unsaved false
		set ::status "Reloaded"
	}

}


# Prompt user for file to open:
proc prompt_open_file {} {
	# TODO: handle filename being empty?  Or do that in open_file itself?
	open_file [tk_getOpenFile -title "Open text file for editing"]	;# -initialdir -initialfile -message "Select text file to open for editing"
}

# Likewise, but for inserting/append the text into the current buffer:
proc prompt_insert_file {} {
	# We don't just use [load_file] here, because we want slighly different behaviour (namely to highlight the new text).
	insert_file [tk_getOpenFile -title "Open text file for editing"]
}



# Save to already known filename
proc save {} {
	if {$::filename == ""} {
		prompt_save_as
	} else {
		save_to $::filename	;# Re-use save_to proc
	}
}

# Save to specific filename and remember it:
proc save_as {filename} {
	if {$filename == ""} {
		set ::status "Cancelled/No file specified"
		return
	}
#	lock $filename	;# No, leave the locking of the new file to the save_to procedure.
	unlock $::filename	;# unlock the old file.
	set ::filename $filename
	save
}

# The core "save" command: save to specific file (without changing ::filename)
# This could be called from "Save", "Save As", or "Save a Copy as"!
# TODO: some error handling?
# Haha, my first test of this found a problem: attempting to write to an existing FIFO!  TODO: remedy.
proc save_to {filename} {
	if {$filename == ""} {
		set ::status "Cancelled/No file specified"
		return
	}
	# Check that it's safe to write, by making sure there's no lock on the file already.
	if {![lock $filename]} {error "save_to $filename: file is locked! ([get_lock_data $filename])"}	;# TODO: GUI interaction
	# TODO: When to unlock that file is a bit murky, I think.  It depends on what called save_to.  At present I think this will leave locks hanging around after "Save a Copy As" operations!
	set ::status "Saving…"
	log_file_operation $filename SAVE
	# TODO: Make backup/versioned copy always as well?  Perhaps a new proc for that, huh?
	# file stat /tmp/test.txt file_stats
	# file copy SOURCE TARGET
	set file [open $filename w]
	puts -nonewline $file [get_all]	;# Hmm, even with -nonewline we're ending up with extra creeping newlines appearing each time we save (or open?).  TODO: fix.  I think it might be the text widget itself that's generating these (one school of thought is that every text file must end in a newline).
	close $file
	set_unsaved false
	set ::status "File saved"
}


# I think we need "Save As" and "Save To" prompted wrappers here too.
# Prompt user for filename to save as:
proc prompt_save_generic {} {
	# TODO: handle filename being empty?  Or do that in 
	# NOTE: -confirmoverwrite not really widely available enough (not in Tk 8.5.8?!)
	tk_getSaveFile -title "Filename to save as"	;# -initialdir -initialfile -confirmoverwrite true
}

proc prompt_save_as {} {save_as [prompt_save_generic]}	;# Save here, and remember the filename

proc prompt_save_to {} {save_to [prompt_save_generic]}	;# Save a copy here, but retain the current filename


# Isn't this basically the same as "new"?
#proc close_file {} {new}
proc close_file {} {puts stderr "** clear..."; flush stderr; clear}



# Navigation commands:

# TODO: command: jump to line x.
proc jump_to_line {line_number} {
}


# TODO: support for opening a file from a URL?  Maybe callout to wget/curl?



# Search
#  - from here or from start by default?
#  - dialog child window or panel element?  Would prefer non-obscuring panel really..have it always there and just show/hide?  Top or bottom?  Or side, maybe (for those with widescreen displays)?
# - interaction with folding?
# - Elided text???

# Whoops - misunderstood: -count returns number of chars, not number of occurrences found.

proc find {search_term} {
	set match_length 0

	# Where should the search start?  Start of document or current "insert" mark?  If there's a selection (especially one from a previous search for the same search_term), we should probably search from the end of that.
	set search_start [.editor.text index insert]	;# Default starting position is the "insert" mark.
	# Now we see if we can override that with the end of the current selection:
	set selection_end [lindex [.editor.text tag ranges sel] end]	;# the "sel" range could consist of multiple ranges; grab the last one! (TODO: what if searching backwards?!)
	if {$selection_end != ""} {
		# Hmm, the ranges will be coming in pairs.  I guess it's enough just to grab the last one, which will always be the end of the last selection.
		set search_start $selection_end
	}
#	puts stderr "search_start = $search_start"

	set search_result [.editor.text search -count match_length $search_term $search_start end]
#	puts stderr "match_length = $match_length"
#	puts stderr "search_result = $search_result"

	# Proceed only if something found:
	if {$match_length > 0} {
		set ::status "Found"
		.editor.text tag add sel $search_result "$search_result + $match_length chars"
#		.editor.text tag add sel $search_result "$search_result + [string length $search_term] chars"
		.editor.text see $search_result
		.editor.text mark set insert $search_result
	} else {
		puts stderr "\"$search_term\" not found."
		set ::status "Not found"
	}
	unset match_length
	unset selection_end
	unset search_start
}

# Interestingly, each search continues adding ranges to the selection. :)  Could be good to make use of that...

# Text replacement (e.g. for Find/Change AKA Search/Replace) is really a transformation, so see functions.tcl for that instead.
proc replace_all {original replacement} {
	# TODO: might be nicer to have it use the "find" mechanism so that replaced text is left selected after being replaced.
	select_all
	transform_selection ::piaf::transform::replace_all $original $replacement
}




# Reference commands, including Web searches and the like:


# Take selected text and open as URL in browser:
proc open_selection_in_browser {} {
	set ::status "Opening browser…"
	exec $::browser [string trim [get_selection]] 2> /dev/null &
	set ::status "Ready"
}

# TODO: factor out common browser code.  Perhaps use string substitution for search term placeholder.  Definitely think about applying some URL-encoding.

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


# Callouts to the awesome Frink calculator:

proc start_frinkserver {} {
	# We can share one frinkserver among multiple Piaf instances. Only launch frinkserver if it's not already running:
	if {[catch {send frinkserver {puts stderr {Piaf instance connected}}}]} {
		exec "$::binary_path/frinkserver.tcl" >& /dev/null &
	}
}

proc stop_frinkserver {} {
	catch {send frinkserver {quit}}
}

# Assuming background frinkserver.tcl is running:
proc frink {expression} {send frinkserver [list frink $expression]}	;# Internal command for running Frink expressions

# Higher-level command for evaluating editor text in Frink and inserting the result in the document
# TODO: cater for multiple selection ranges?!  Perhaps iterate through them all, evaluating each one.
proc frink_eval {} {
	# Ensure it's running (start_frinkserver only starts a new instance if required; however, it does take a long time to start up - TODO: figure out a way to deal with this)
	start_frinkserver
	set expression ""
	# Figure out what text to send to Frink for evaluation:
	if {[.editor.text tag ranges sel] != ""} {
		# Use selection if it exists
		set expression [get_selection]
		.editor.text mark set insert [lindex [.editor.text tag ranges sel] end]	;# Jump to end of current (or at least last!) selection
	} else {
		# Otherwise the current line
		set expression [get_current_line]
		.editor.text mark set insert "insert lineend"	;# Jump to end of current line
	}
	set result [frink $expression]
	if {$result != ""} {insert "\n$result"}

	unset result
	unset expression
}

# For simple text filters that require no additional arguments:
proc transform {function text} {::piaf::transform::$function $text}
# TODO: could maybe generalise to support extra args?  What was the Tcl convention for that again?  "args"?

# Apply a text transformation function to the selected text, replacing it in the editor.
# NOTE: currently does not handle the case of the "sel" mark having multiple ranges!
# Also, somehow handle invoking this with no selection active.  Could maybe just do nothing if there's no selection...but this function might also be used for generators, in which case there might not be a selection.
# TODO: currently this plays strangely with undo: the deletion counts as an extra operation.  Can we exempt that somehow?
# TODO: a similar "transform_all" which will be applied if no text is selected.  Will need to factor out common behaviour and put in another new proc.
proc transform_selection {function args} {
	set ::status "Transforming…"
	set initial_insert_mark [.editor.text index insert]	;# Remember initial insert point
	set text [get_selection]	;# Copy original text
#	set transformed_text [transform $function $text]
	set transformed_text [$function $text {*}$args]
	.editor.text delete sel.first sel.last	;# Remove the selected text (to be replaced with transformed)
	set sel_start [.editor.text index insert]	;# Note start of new sel range
	.editor.text insert insert $transformed_text	;# Insert the transformed text
	set sel_end [.editor.text index insert]	;# Note end of new sel range
	.editor.text tag add sel $sel_start $sel_end	;# Restore selection range to the new text.
	.editor.text mark set insert $initial_insert_mark	;# Might be wrong? Esp. if sel changes size?
	unset text
	unset transformed_text
	event generate .editor.text <<Modified>>
	set ::status "Transformed"
}

# Might it make sense to have simple wrappers for transformation functions for use in scripts?  What if we want to have commands figure out for themselves whether to apply to the current selection, the entire buffer, or automatically work out a suitable selection if there is none?
proc rot13 {} {transform_selection ::piaf::transform::rot13}


# For generator functions, it's much simpler:
proc insert {text} {.editor.text insert insert $text}

proc insert_ascii {} {insert [::piaf::generate::ascii]}


proc quit {} {
	set ::status "Exiting…"
	# Check for unsaved changes (and/or auto-save recovery files)
	check_for_unsaved_changes
	unlock $::filename
#	if {![.editor.text edit modified]} {}
	# Maybe prompt for user certainty regardless?
	# Log QUIT operation as well?
	if {$::use_database} {
		puts "Closing database…"
		::piaf::database close
	}
	puts "Exiting…"
	exit
}







