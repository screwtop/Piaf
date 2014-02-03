# Use an external process for lexical scanning, processing the text line by line (to avoid hanging up the GUI).
# For even greater efficiency, it would be nice to leave the scanner process running, and have it reopen its stdin once it's reached EOF so it can start scanning afresh without us having to start a new process.
# There is some trickiness there: we'd like to feed it lines of input one by one, to keep the GUI alive while scanning is done, but I'm not sure how to send EOF to the pipeline (other than by closing it), or how to write the scanner (in Flex) so that it can reopen stdin/out.  I think for now we just have to run the scanner process anew for each pass.

# Ah, Tcl 8.6 introduces the ability to half-close a channel, which would be just the ticket here!

# Note that the general arrangement here is the same as for using aspell in a pipeline, and for the char/word/line count scanner.  It might be possible/good to generalise.

# Callback for when results are received from the scanner:
proc process_scanner_results {chan} {
#	puts stderr "process_scanner_results called. chan = $chan"
	# No, I don't think we actually want a while loop here, because that will bypass the event-driven I/O approach.
	if {[gets $chan line] >=0} {
	#	puts stderr "process_scanner_results: got <<$line>>"
		if {[regexp {^([^	]+)	([0-9]+)	([0-9]+)$} $line entire_match lexical_element start_char end_char]} {
		#	puts stderr "MATCH: $lexical_element (start=$start_char, end=$end_char)"
			.editor.text tag add $lexical_element "1.0 + $start_char chars" "1.0 + $end_char chars"
		#	after idle [list after 0 [list .editor.text tag add $lexical_element "1.0 + $start_char chars" "1.0 + $end_char chars"]]
		}
		# Signal to the highlight_syntax routine that we're done with the current line and ready for the next:
		# Ah, but if there's no output from a line (e.g. no symbols), then this callback won't even be called!
		# And if there are multiple lines returned (multiple tokens), then ::scanner_line_completed should only be set after all the tokens for the line have been processed, and we won't know when that is.
	#	set ::scanner_line_completed true
		return
	} elseif {!$::scanning_in_progress} {
	#	puts stderr "process_scanner_results: OK to close channel."
		close $chan
		set ::scanner_closed true
		return
	} elseif {[eof $chan]} {
	#	puts stderr "process_scanner_results: EOF on $chan detected/requested"
	#	catch {chan close $chan read}	;# Requires Tcl 8.6. :(
		catch {close $chan}
		set ::scanner_closed true
		return
		;# Might want to use a vwait somewhere to detect and restart the scanner automatically?
	} else {
		# Even with this we sometimes see missing highlighting resulting from scanner output not being read before the pipeline closes.
	#	puts stderr "process_scanner_results: unknown condition; will try to continue..."
		return
	}
}


# Callback for when the scanner pipeline is readable:
set ::line_number 1
proc send_line_to_scanner {chan} {
#	puts stderr "send_line_to_scanner called!"
	set line [.editor.text get $::line_number.0 "$::line_number.0 lineend"]
#	puts stderr "Sending line $::line_number: <<$line>>"
	puts $chan $line
#	after idle {after 0 [list puts $::chan $line]}	;# Also flush?  Or not necessary since -buffering line?
	# Check if there are more lines remaining:
	if {$::line_number < [lindex [split [.editor.text index end] .] 0]} {
		incr ::line_number
	} else {
	#	puts stderr "send_line_to_scanner: No more lines - attempting to close pipeline."
		chan flush $chan
		process_scanner_results $chan	;# In the hope that that will avoid any last dribs of output from being lost.  Doesn't work.
	#	after idle [list close $chan]
	#	puts stderr "Pending bytes: [chan pending input $chan] in, [chan pending output $chan] out"
		# We don't have half-closing of channels in 8.5, but maybe [chan pending ...] will work instead...Nope, it's always reporting 0.
	#	if {[chan pending input $chan] == 0} {
		#	close $chan	;#  WARNING: race condition!  There might still be output yet to be received from the scanner, so we don't want to close just yet!  But we need to close to signal EOF to the scanner.  Hmm.  Maybe we can use a global variable to signal that we want the reader callback to close the channel.  I think we really want Tcl 8.6's "chan close $chan <direction>".
			set ::scanning_in_progress false
		#	chan configure $chan -blocking true
		#	vwait ::scanner_closed
	#	}
		# Ah-ha: we can half-close the pipe channel with "chan close <direction>!":
	#	chan close $chan write	;# Oh, requires 8.6. :(
	}
}


set ::scanning_in_progress false

proc highlight_syntax {language} {
	if {$::language == ""} {return}
	if {$::scanning_in_progress} {return "$language lexical scanning already in progress."}
	set ::scanning_in_progress true

	if {[catch {set ::scanner_pipe [open "|$::binary_path/scanners/$language" r+]} error]} {
		set ::scanning_in_progress false
		error "Failed to open scanner for $language: $error"
	}
	# Let's try a pair of FIFOs instead:
#	set ::scanner_input_pipe [open "input" w]
#	set ::scanner_output_pipe [open "output" r]	;# Bah, this blocks. :(  Dang FIFOs.
	chan configure $::scanner_pipe -buffering line -blocking 0
	chan event $::scanner_pipe readable [list process_scanner_results $::scanner_pipe]

	# Remove existing highlighting:
	# TODO: foreach-ify this (just lift from scanning.tcl)
	# Will just test with comments for now...
	.editor.text tag remove comment 1.0 end

	# Let's try also using event-driven processing for sending the lines to the scanner:
	set ::line_number 1
	chan event $::scanner_pipe writable [list send_line_to_scanner $::scanner_pipe]

# Disabling loop-driven approach for now:
if 0 {
	# Iterate through the lines in the current text editor buffer, sending them to the scanner:
	for {set ::line_number 1} {$::line_number < [lindex [split [.editor.text index end] .] 0]} {incr ::line_number} {
		set line [.editor.text get $::line_number.0 "$::line_number.0 lineend"]
		puts "Sending line $::line_number: <<$line>> (::scanner_pipe = $::scanner_pipe)"
		# TODO: try using fileevent to ensure that the pipe is ready for writing, and use {after idle {after 0 ...}} to append each new line.  As long as we can ensure that they will be transferred in order!
		# Send scanner a line to check (with hacky EOL marker appended):
		# NOTE: can't use [after idle] unless also using [vwait] below, I think.
		puts $::scanner_pipe $line
		flush $::scanner_pipe
	#	after idle [list puts $::scanner_pipe $line]
		#	puts $::scanner_pipe $line
		#	flush $::scanner_pipe	;# Not necessary if using "-buffering line", right?
		# Hmm, there's a problem if the scanner returns nothing in response to a submitted line: the callback does not get called in that case, as there is no output to retrieve.  We therefore can't use vwait here (waiting for the callback to set the variable when done).
		# Alternatively, we could try to design the scanner so that it at least reports NULL or EOL at each line.  That might be useful, but I'd rather make this code here more robust.
	#	vwait ::scanner_line_completed
	#	unset ::scanner_line_completed
	}
}
	# How do we send EOF to the scanner?  Just close the pipe?

	# Ah, but the callback can detect EOF, and set a variable that this procedure can wait on:
#	vwait ::scanner_closed
	# ...only I have no idea how to signal EOF from this routine...
#	puts stderr "Got EOF on scanner; closing up..."

#	set ::scanning_in_progress false
#	close $::scanner_pipe
#	unset ::scanner_pipe
}







