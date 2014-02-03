# Common stuff for scanning/lexical highlighting/syntax colouring.
# TODO: maybe refactor so that [get_all] is called only once per pass, and the per-language scanner procs access that globally.
# TODO: file type identification and loading of an appropriate scanner (these are stored in the "scanners" directory).
# TODO: run scanners in a separate process to avoid interfering with the main GUI!
# TODO: prevent scanner-inserted tags from interfering with the file modification status.

# Some general setup first: apply colouring/highlighting preferences:
.editor.text tag configure comment -foreground $::comment_foreground_colour
.editor.text tag configure string -foreground $::string_foreground_colour
.editor.text tag configure keyword -foreground $::keyword_foreground_colour -font $::keyword_font;# bold? that's a font attribute.
.editor.text tag configure symbol -foreground $::keyword_foreground_colour -font $::keyword_font
.editor.text tag configure literal -foreground $::literal_foreground_colour
.editor.text tag configure identifier -foreground $::identifier_foreground_colour
# and, for testing:
.editor.text tag configure TEST -background red -foreground white -font $::keyword_font

# Now, try to get the tag priority right:
.editor.text tag raise keyword symbol
.editor.text tag raise string keyword
#.editor.text tag raise identifier string
.editor.text tag raise comment string
.editor.text tag raise comment literal
.editor.text tag raise sel	;# To keep things simple when highlighting coloured text, we just have the selection style dominate.
.editor.text tag raise TEST comment


# Remove all ranges for the specified tag:
proc clear_tag {tag_name} {
	.editor.text tag remove $tag_name 1.0 end
}

# Generic "scan text for regexp X and tag as Y".
# This will be called repeatedly by the "tag_all" procedure.
# You can use non-capturing groups in the regexp for a lexical element, e.g. "(?:LEADING_CONTEXT)(MATCH_THIS)(?:TRAILING_CONTEXT)".  This procedure will query the number of groups (not the non-matching ones) and make sure it ignores the indexes returned for the entire range (if applicable).
proc tag {regexp tag_name} {
	clear_tag $tag_name
	
	# The correct stride of this foreach loop depends on the number of match groups in the regexp.  Find out how many submatches the regexp involves, and set up the loop variable list accordingly:
	if {[lindex [regexp -about -all -indices -inline $regexp {}] 0] == 0} {
		set var_list {index}
	} else {
		set var_list {ignore index}
	}
	foreach $var_list [regexp -all -indices -inline $regexp [get_all]] {
		set start [lindex $index 0]
		set end [expr {[lindex $index 1] + 1}]
		.editor.text tag add $tag_name "1.0 + $start chars" "1.0 + $end chars"
	}
	catch {unset index}
	catch {unset ignore}
}


# Maybe the main scanner would look something like:
# A good way to encode the symbols and REs for a language scanner might be to use an (associative) array, perhaps named ::scanner_regexp.  It would have an element for each generic lexical element that could be present in a language (indeed, maybe missing some).  Each time you load a language scanner, it'll can just replace the other stuff (but don't forget to use unset/array unset to avoid stuff hanging around!).
# e.g. set ::scanner_regexp(keyword) {eval|exec|exit|expr|foreach|package|proc|puts|require|set|...}
proc tag_all {} {
	# set text [get_all]	;# TODO: enable this and only fetch once!
	foreach lexical_element {TEST comment identifier literal string number keyword operator symbol variable} {
		# The regexp context is optional; dealing with that is surprisingly annoying (::scanner_regexp_context($lexical_element) might not exist).
		catch {tag $::scanner_regexp($lexical_element) $lexical_element}	;# catch, to ignore any that don't exist
	}
}


# The stuff above has basically been superseded by the following code, which makes use of external processes to do the scanning in parallel and asynchronously:


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
		#	puts stderr "process_scanner_results: MATCH: $lexical_element (start=$start_char, end=$end_char)"
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
		puts stderr "process_scanner_results: unknown condition; will try to continue..."
		return
	}
}


# Callback for when the scanner pipeline is readable:
# Good tips here on avoiding starving the event loop because of ever-ready write end of the pipeline:
# https://groups.google.com/forum/#!topic/comp.lang.tcl/-vkULUOqIHA
proc deferred_send_line_to_scanner {chan} {
	chan event $chan writable {}
	send_line_to_scanner $chan
	after idle [list after 50 [chan event $::scanner_pipe writable [list send_line_to_scanner $::scanner_pipe]]]	;# And resume again when idle.  Only that results in trying to write again after the channel has been closed!

}

set ::line_number 1
proc send_line_to_scanner {chan} {
#	puts stderr "send_line_to_scanner called!"
	set line [.editor.text get $::line_number.0 "$::line_number.0 lineend"]
#	puts stderr "Sending line $::line_number: <<$line>>"
	puts $chan $line
	chan flush $chan
	# Check if there are more lines remaining:
	if {$::line_number < [lindex [split [.editor.text index end] .] 0]} {
		incr ::line_number
	} else {
	#	puts stderr "send_line_to_scanner: No more lines - attempting to close pipeline."
		chan flush $chan
	#	process_scanner_results $chan	;# In the hope that that will avoid any last dribs of output from being lost.  Doesn't work.
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
		chan close $chan write	;# Oh, requires 8.6. :(
	}
}


set ::scanning_in_progress false

proc highlight_syntax {language} {
	if {$::language == ""} {return}
	if {$::scanning_in_progress} {return "$language lexical scanning already in progress."}
	set ::scanning_in_progress true

	# TODO: try using [asyncexec] instead of this:

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
	# Is this the place to add appropriate [after] calls to avoid excessive busyness?
	set ::line_number 1
	chan event $::scanner_pipe writable [list deferred_send_line_to_scanner $::scanner_pipe]

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


# Lastly, arrange for the highlighting to be refreshed periodically:
# For using the external scanner processes:
set ::language "";# TODO: maybe have this in settings - could default to English.
every $::highlight_interval_ms {highlight_syntax $::language}
#every $::highlight_interval_ms tag_all
# TODO: How do we cancel that, if we ever want/need to turn the live highlighting off?

