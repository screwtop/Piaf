# Basic spellcheck capability (not realtime yet - will need to be implemented as a separate process - and I'm not sure what IPC method would be best there, as there would often be too much text for [tk send]).

# Now uses an array, since in Tcl these are implemented as a hash.
# Spellcheck using list for ::dictionary: 6.3 seconds for MPlayer docs vidix.txt (858 words).
# Using a hash took it down to 42 milliseconds for the same text. ;)

proc load_dictionary {filename} {
	puts -nonewline stderr "Loading dictionary from \"$filename\"…"
	foreach word [slurp $filename] {set ::dictionary([string tolower $word]) 1}
	puts stderr "done."
}

load_dictionary $::dictionary_file	;# Main dictionary file

# Also load user dict(s) (todo: settings for multiple custom dictionaries; for now just load them all):
foreach dictionary_file [glob -nocomplain ~/.piaf/dictionaries/*] {
	catch {load_dictionary $dictionary_file}
}

# Print dictionary stats:
puts stderr "[array size ::dictionary] words loaded."
puts stderr "[array statistics ::dictionary]\n"

.editor.text tag configure misspelled -foreground $::misspelled_foreground_colour -underline true


# Case-sensitivity?  Could convert to lowercase when creating the array, and also when looking up...
proc word_exists {word} {
	if {[catch {set result $::dictionary([string tolower $word])}]} {
		set result 0
	}
	return $result
}


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
	#	if {[lsearch -nocase $::dictionary $word] == -1} {}
		if {![word_exists $word]} {
			# Unrecognised word: highlight!
		#	puts stderr "Unrecognised: \"$word\" (chars $start-$end)"
			.editor.text tag add misspelled "1.0 + $start chars" "1.0 + [expr {$end + 1}] chars"
		}
	}
}

# TODO: alias "check_spelling" for "spellcheck"?

# Remove all the "misspelled" tag ranges to clear them.
proc clear_spelling_errors {} {
	foreach {start_index end_index} [.editor.text tag ranges misspelled] {
		.editor.text tag remove misspelled $start_index $end_index
	}
}





