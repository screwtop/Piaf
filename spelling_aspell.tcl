# Spelling with aspell (using a pipe)

# Probably makes sense for each Piaf instance to have its own aspell instance (sharing them is probably not scalable, and each probably needs its own language settings anyway).

	# Where should "after idle" go here?  Around the lot? OR just the output?  Would need to use ::line instead if so..or construct the "after" body literally using [list]?
	# In order to highlight misspelled words, this proc needs to know what line number was being checked.  However, aspell only deals with one line at a time, and reports only the character indexes for the current line.  Because the procesing of results from aspell is asynchronous, we have no way of passing the line number to this proc.  So, we probably have to send a line to aspell and deal with the results before sending another line, so that this proc can read the current line number variable itself.
	# It will probably also be necessary to inject a phony misspelled word at the end of each line so that we can detect that there are no more misspellings for the current line and can continue with the next.  Something like " PIAF_ASPELL_EOL".

proc process_aspell_results {chan} {
	gets $chan line
	puts stderr "\n\nAspell output = <<$line>>"
	if {[eof $chan]} {close $chan; set ::aspell_closed true}	;# Might want to use a vwait somewhere to detect and restart aspell automatically.
	# Extract spelling info:
	if {[regexp {^& ([^ ]+) ([0-9]+) ([0-9]+): (.*)$} $line entire_match word count offset alternatives]} {
		puts stderr "word = $word"
		# Detect EOL:
		if {$word == "PiafAspellEOL"} {
			# We're done for the current line.
			puts stderr "Done with line $::spellcheck_line_number"
			set ::aspell_line_completed true
			return
		}
		set start [expr {$offset - 1}]	;# Aspell indexes from 1, Tcl from 0
		set end [expr {$start + [string length $word]}]
		puts "$word (line=$::spellcheck_line_number, chars $start-$end)"
		# Ah, we need to be told the line number as well.  Somehow.  Variable shared with the checker loop?
		.editor.text tag add misspelled $::spellcheck_line_number.$start $::spellcheck_line_number.$end
		puts [string map {{,,} { }} [join $alternatives {,}]]
		# TODO: create a Spelling pop-up menu and tag the misspelled words to use it.
	}
	if {$line == ""} {set aspell_line_completed true}
	# if {$line == "*"} {??}
}

proc start_aspell {} {
	catch {stop_aspell}
	puts -nonewline stderr "Starting aspell..."
	set ::aspell_pipe [open "|aspell pipe" RDWR]
	fconfigure $::aspell_pipe -buffering line -blocking 0
	chan event $::aspell_pipe readable [list process_aspell_results $::aspell_pipe]
	# TODO: put aspell in terse mode (recommended for faster operation in pipe mode).
	puts stderr "done."
}

proc stop_aspell {} {
	puts -nonewline stderr "Stopping aspell..."
	close $::aspell_pipe
	puts stderr "done."
}


proc spellcheck_aspell {} {
	# TODO: First, make sure a spellcheck isn't already in progress!
	# ...

	# Remove existing tag ranges:
	.editor.text tag remove misspelled 1.0 end

	for {set ::spellcheck_line_number 1} {$::spellcheck_line_number < [lindex [split [.editor.text index end] .] 0]} {incr ::spellcheck_line_number} {
		set line [.editor.text get $::spellcheck_line_number.0 "$::spellcheck_line_number.0 lineend"]
		puts "Sending line $::spellcheck_line_number: <<$line>>"
		# Send aspell a line to check (with hacky EOL marker appended):
		# Oh, dear: aspell treats certain prefix characters specially in its line input.  TODO: strip these.
		# string trimleft $line {SPECIAL_HEADER_CHARS}
#		puts $::aspell_pipe [concat [string map {"~" " "} [string trimleft $line {*&@+-~#!%^}]] PiafAspellEOL]
		# Oh, wait: the correct way to get around this is to prefix every line with a "^", which will cause aspell to ignore special characters remaining in the line.
		puts $::aspell_pipe "^$line PiafAspellEOL"
#		after idle ... ?
		# Don't proceed until Aspell has processed the line it's been given (otherwise we won't know what line the reported errors occured on).
		vwait ::aspell_line_completed
		unset ::aspell_line_completed
	}
}

# Make this the default "spellcheck" command:
interp alias {} spellcheck {} spellcheck_aspell
interp alias {} check_spelling {} spellcheck_aspell

start_aspell

