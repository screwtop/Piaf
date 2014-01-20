# Things involved in tracking modifications to the text.
# Dang, I realised I was trying to do two different things here with <<Modified>>: detecting if the file has changed since it was last saved, and detecting any changes to the text ever. :(  Now, the <<Modified>> event only happens when the state of the flag (as returned by [.editor.text edit modified]) changes, not on every actual modification to the buffer!  Remember also that setting the flag to false (only if it's currently true?) will trigger <<Modified>>!  Anyway, maybe I can use the <<Modified>> event and a couple of variables to keep track of both.
# Let's use ::unsaved for outstanding changes, and consider only that from elsewhere in Piaf that needs to know if there are unsaved changes.  TODO: some refactoring there.
# Then we'll always ".editor.text edit modified false" whenever we've detected a change.



# Generic handler that can be called by a command that will lose changes if it proceeds (e.g. New, Close, Exit).
# Will check for unsaved changes (trusting $::unsaved to be correct), prompt if necessary, and return success if all's well.
proc check_for_unsaved_changes {} {
	# TODO: loop?
	if {$::unsaved} {
	#	handle_closing_unsaved_attempt
		# Notify:
		set ::status "Unsaved changes!"
		puts stderr "Unsaved changes! Awaiting user choice..."
		show_unsaved_panel
	#	grid configure .unsaved   -row 2 -column $::main_column -sticky ew	;# Show "Unsaved Changes" panel
		focus .unsaved.save
		# Maybe this is one instance where a modal dialog would actually be appropriate...!  Need to pause here until the user has made their decision.
	#	check_for_unsaved_changes	;# Ha, recurse!  After a delay?  TODO: what about recursion limit?
		# Or how about vwait?!  Have the button commands on the Unsaved Changes panel set a "good to go" type variable, which we can detect here.  Or will that hang the GUI?
		# TODO: how to handle the operation being cancelled?  Maybe check the value of the vwait variable and see what the action was, and raise an error/exception to cause the operation to be cancelled.
		catch {unset ::unsaved_condition_dealt_with}
		vwait ::unsaved_condition_dealt_with
		puts stderr "User chose: $::unsaved_condition_dealt_with"
		grid forget .unsaved
		if {$::unsaved_condition_dealt_with == "cancel"} {
			error "Operation cancelled!"
		}
		focus .editor.text
		set ::status "Ready"
	}
	return -code ok
}



# Colour extent of the buffer text so we can see EOF.
.editor.text configure -background $::void_colour
.editor.text tag add extent 0.0 end
.editor.text tag configure extent -background $::background_colour
.editor.text tag lower extent current_line

proc update_text_extent_display {} {
	# Update text extent background colouring:
	.editor.text tag remove extent 1.0 end
        .editor.text tag add    extent 1.0 end
}

# Routines for showing/hiding the mouse pointer/cursor (pretty much only relevant for not obscuring the user's view of the editor while making changes, but could be called from elsewhere too I guess):
# TODO: only bother actually changing the cursor if it's in the wrong state?  Yes: resetting the mouse cursor also causes the insert point to reset!
set ::mouse_pointer_enabled true
proc hide_mouse_pointer {} {
	if {$::mouse_pointer_enabled} {
		.editor.text configure -cursor none
		set ::mouse_pointer_enabled false
	}
}
proc show_mouse_pointer {} {
	if {!$::mouse_pointer_enabled} {
		.editor.text configure -cursor [lindex [.editor.text configure -cursor] 3]
		set ::mouse_pointer_enabled true
	}
}

# Restore the mouse pointer/cursor when the mouse is moved
# TODO: maybe flash the pointer briefly to make it easy to spot?
bind .editor.text <Motion> show_mouse_pointer
# and other mouse events too? Buttons?
bind .editor.text <ButtonPress> show_mouse_pointer
bind .editor.text <ButtonRelease> show_mouse_pointer

# Detect file modification.  We need to know if it's been modified to know whether to allow quitting without saving, and also to adjust the text extent tag range for showing EOF.
set ::unsaved false
proc text_modification_handler {} {
	;# WARNING: don't clobber existing binding!
#	puts stderr "<<Modified>>: text_modification_handler called; filename=$::filename; ::unsaved=$::unsaved"
	# NOTE: we DO need to check this result, because (oddly, IMO) setting the flag to false will actually trigger <<Modified>>.
	if {[.editor.text edit modified]} {
		set ::status Modified
		set ::unsaved true
		# Hide mouse pointer while typing (TODO: maybe save initial cursor setting so we can restore it correctly; on Linux/X11, the default cursor for text widgets is "xterm"):
		hide_mouse_pointer
		update_text_extent_display
		# Lastly, reset the modified flag for the text widget so we can detect the next modification:
		.editor.text edit modified false
		# TODO: is it really necessary to [after idle] these?!  Might it not be better to have it executed synchronously/sequentially?
	#	after idle {.editor.text edit modified false}
	}
	# Regardless of what we just did, set the modified flag back to false so we can detect the next modification.  Uh, but we can't do that, because it would cause infinite recursion of <<Modified>> events.  Well, at least Tcl detects that and puts a stop to it!
	# Could we schedule something using [after]?  If we use [after idle], we peg the CPU, but it does work.  [after 0] would hang the GUI.  If we used a timed delay, we might miss fast edits.  Hmm.
#	after idle {.editor.text edit modified false}
	# Try doing it only conditionally, in the "modified true" block above
}

bind .editor.text <<Modified>> text_modification_handler

# TODO: Could possibly want to log the file modification event to the file log as well (the event is only triggered by the first modification).
# Interestingly (and kind of annoyingly), the act of setting the "modified" flag to false also triggers the <<Modified>> event!

# TODO: fix very strange thing that happens if you go to the end of the text, Shift+RightArrow to select the rest of the line (which shouldn't really be anything because there's no linebreak there), and press Enter/Return.  <<Modified>> events for the text widget then don't happen (until you call close_file anyway).








