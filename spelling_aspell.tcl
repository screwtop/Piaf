# Spelling with Aspell (using a pipe)

# Probably makes sense for each Piaf instance to have its own aspell instance (sharing them is probably not scalable, and each probably needs its own language settings anyway).

# Where should "after idle"s go in all this?  Around the lot? OR just the output?  Would need to use ::line instead if so..or construct the "after" body literally using [list]?

# In order to highlight misspelled words, this proc needs to know what line number was being checked.  However, aspell only deals with one line at a time, and reports only character indexes for the current line (not the line number).  And because the procesing of results from aspell is asynchronous, we have no way of passing the line number to this proc.  So, we have to send a line to aspell and deal with the results before sending another line to it, so that the process_aspell_results callback can read the current line number variable as set by spellcheck_aspell.
# It proved necessary to inject a phony misspelled word at the end of each line so that we can detect that there are no more misspellings for the current line and can continue with the next.  This is the "PiafAspellEOL" string that appears in a couple of places in the code.

proc process_aspell_results {chan} {
	if {[eof $chan]} {
		catch {close $chan}
		set ::aspell_closed true
	}	;# Might want to use a vwait somewhere to detect and restart aspell automatically.
	gets $chan line
#	puts stderr "\n\nAspell output = <<$line>>"
	# "*" indicates a correctly-spelled word; "" (empty lines) will sometimes occur if the line sent for checking starts with certain special characters.  Empty responses also happen sometimes when it's not the start of a newline; TODO: figure this out exactly.  In the meantime, it's probably best to replace special characters with spaces in the lines before aspell gets to see them.
	if {$line == ""} {
	#	set ::aspell_line_completed true
		return
	}
	if {$line == "*"} {return}	;# Correct spelling; carry on...
	# Extract spelling info:
	if {[regexp {^& ([^ ]+) ([0-9]+) ([0-9]+): (.*)$} $line entire_match word count offset alternatives]} {
#		puts stderr "word = $word"
		# Detect EOL:
		if {$word == "PiafAspellEOL"} {
			# We're done for the current line.
#			puts stderr "Done with line $::spellcheck_line_number"
			set ::aspell_line_completed true
			return
		}
		set start [expr {$offset - 1}]	;# Aspell indexes from 1, Tcl from 0
		set end [expr {$start + [string length $word]}]
#		puts "$word (line=$::spellcheck_line_number, chars $start-$end)"
		.editor.text tag add misspelled $::spellcheck_line_number.$start $::spellcheck_line_number.$end
#		puts [string map {{,,} { }} [join $alternatives {,}]]
		# TODO: create a Spelling pop-up menu and tag the misspelled words to use it.
	}
	if {$line == ""} {set aspell_line_completed true}
	# if {$line == "*"} {??}
	return
}

proc start_aspell {} {
	catch {stop_aspell}
	puts -nonewline stderr "Starting aspell..."
	set ::aspell_pipe [open "|aspell pipe" r+]	;# Or RDWR?
	fconfigure $::aspell_pipe -buffering line -blocking 0
	chan event $::aspell_pipe readable [list process_aspell_results $::aspell_pipe]
	puts $::aspell_pipe "!"; flush $::aspell_pipe	;# Put aspell in terse mode (recommended for faster operation in pipe mode).
	puts stderr "done."
}

proc stop_aspell {} {
	puts -nonewline stderr "Stopping aspell..."
	close $::aspell_pipe
	puts stderr "done."
}


set ::spellcheck_in_progress false

proc spellcheck_aspell {} {
	# TODO: First, make sure a spellcheck isn't already in progress!
	# ...
#	if {[info exists ::spellcheck_in_progress]} {return "Spellcheck already in progress."}
	if {$::spellcheck_in_progress} {return "Spellcheck already in progress."}
	set ::spellcheck_in_progress true

	# Remove existing tag ranges:
	.editor.text tag remove misspelled 1.0 end

	for {set ::spellcheck_line_number 1} {$::spellcheck_line_number < [lindex [split [.editor.text index end] .] 0]} {incr ::spellcheck_line_number} {
		set line [.editor.text get $::spellcheck_line_number.0 "$::spellcheck_line_number.0 lineend"]
#		puts "Sending line $::spellcheck_line_number: <<$line>>"
		# Send aspell a line to check (with hacky EOL marker appended):
		# Aspell treats certain prefix characters specially in its line input.
		# You can supposedly get around this by prefixing every line with a "^", which will cause aspell to ignore special characters remaining in the line.  But lines like "======", "'..." still seem to cause problems.  We can't just strip ([trimleft]) these because it will mess up the character positions.  Use [string map].
		puts $::aspell_pipe "^[string map {{*} { }  {&} { }  {@} { }  {+} { }  {-} { }  {~} { }  {#} { }  {!} { }  {%} { }  {^} { }  {'} { } {=} { }  {.} { }} $line] PiafAspellEOL"
		flush $::aspell_pipe	;# Necessary if using "-buffering line"?
#		after idle ... ?  Or will that prevent the co-ordination with the callback from working?
		# Don't proceed with the next line until Aspell has processed the line it's been given (otherwise we won't know what line the reported errors occured on).
		vwait ::aspell_line_completed
		unset ::aspell_line_completed
	}
	set ::spellcheck_in_progress false
	return
}

# Make this the default "spellcheck" command:
interp alias {} spellcheck {} spellcheck_aspell
interp alias {} check_spelling {} spellcheck_aspell

start_aspell






