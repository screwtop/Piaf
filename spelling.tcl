# Basic spellcheck capability (not realtime yet - will need to be implemented as a separate process - and I'm not sure what IPC method would be best there, as there would often be too much text for [tk send]).

puts -nonewline stderr "Loading dictionary from \"$::dictionary_file\"…"
#set ::dictionary [slurp $::dictionary_file]
set ::dictionary [list]
foreach word [slurp $::dictionary_file] {lappend ::dictionary $word}
#set ::dictionary [list [slurp $::dictionary_file]]	;# Will this make it faster?
puts stderr "[llength $::dictionary] words loaded."
.editor.text tag configure misspelled -foreground $::misspelled_foreground_colour -underline true


# For proper asynchronous spellchecking, I think we need to make a copy of the entire text in a variable first (for atomicity):
proc spellcheck {} {
	set text [get_all]

	# Remove existing highlighting:
	foreach {start_index end_index} [.editor.text tag ranges misspelled] {
		.editor.text tag remove misspelled $start_index $end_index
	}
	# TODO: apply those removals line by line, as the spellcheck proceeds.
	# Indeed, it would be sensible to limit the spellchecking to the current line, once the main document has been checked once through (in the background).

	# Split into words:
	foreach index [regexp -all -indices -inline "\[A-Za-z\]+" $text] {
		set start [lindex $index 0]
		set end [lindex $index 1]
		set word [string range $text $start $end]
		# Look up word in dictionary:
		if {[lsearch -nocase $::dictionary $word] == -1} {
			# Unrecognised word: highlight!
			puts stderr "Unrecognised: \"$word\" (chars $start-$end)"
			.editor.text tag add misspelled "1.0 + $start chars" "1.0 + [expr {$end + 1}] chars"
		}
	}
}


