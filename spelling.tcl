# General spell-checking setup

# See also spelling_builtin.tcl, spelling_aspell.tcl

# TODO: prevent spelling tags from messing with the file modification status.

.editor.text tag configure misspelled -foreground $::misspelled_foreground_colour -underline true


# Remove all the "misspelled" tag ranges to clear them.
proc clear_spelling_errors {} {
	foreach {start_index end_index} [.editor.text tag ranges misspelled] {
		.editor.text tag remove misspelled $start_index $end_index
	}
}

# TODO: periodic checking (with on/off capability)
#every 1000 check_spelling
# Or just have check_spelling run itself again after idle/delay.  More flexible to be able to call check_spelling on demand, though.  Also to be able to turn off periodic spellchecking.
# Regarding shifting line numbers: at least the text widget will bump existing tags with lines anyway.  Expect some glitches though.  As race conditions go, some shimmering of text highlighting isn't too bad.

