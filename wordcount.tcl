# New wordcount for Piaf using asyncexec:


# Dealing with the output should be quick and easy - the program only outputs one line, right at the end.

proc report {line} {
#	puts stderr "report: <<$line>>"
	if {[regexp "^(\[0-9\]+) chars\t(\[0-9\]+) words\t(\[0-9\]+) lines$" $line entire_match chars words lines]} {
		set ::size_status "${chars}C,${words}W,${lines}L"
	}
}

proc handle_wordcount_output {chan} {
	gets $chan line
	# This could safely use after, yes?  We've already got the line, so the eof below should work.
#	after idle [list after 0 [list puts "[clock microseconds]: <<$line>>"]]
#	after idle [list after 100 [list .editor.text insert end "[clock microseconds]: <<$line>>\n"]]
	after idle [list after 0 [list report $line]]	;# I see about 500 microseconds delay between the external process producing the data and it being received and processed here.
	if {[chan eof $chan]} {close $chan}
}

# For sending each line to the wordcount scanner:

# TODO: move line number variable into wordcount namespace?

set ::line_number 0
proc send_next_line {chan} {
	incr ::line_number
	if {$::line_number < [lindex [split [.editor.text index end] "."] 0]} {
	#	puts stderr "[clock microseconds]: sending line # $::line_number"
		puts $chan [get_line $::line_number]
	} else {
	#	puts stderr "[clock microseconds]: closing $chan for writing"
		close $chan write
		set ::line_number 0
	}
}

# When you want to run a word count, check that one isn't already in progress (::line_number > 0) and do this:
proc wordcount {} {
	if {$::line_number > 0} {return "Word count already in progress"}
#	puts stderr "[clock microseconds]: starting word count"
	asyncexec "$::binary_path/scanners/wordcount" send_next_line handle_wordcount_output {}
}

every 400 wordcount


