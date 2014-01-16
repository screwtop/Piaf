# Lexical scanner for Tcl/Tk code for Piaf.

# TODO: factor out a generic "tag" procedure that accepts a tag name and a regexp and applies the general routine.
# TODO: don't call "get_all" for every single thing - just do it once, store it in a variable, and have the various scanners perform their work on that.
# TODO: longer term, run all this in a background process, so that the GUI will remain responsive no matter how big the file or how complex the language scanner.  This might mean having to stream the editor buffer (line by line? character by character?) - bringing the further complication that the scanner might not ever have an exact copy of the buffer in its curent state (nonatomic).


# Will start with something simple: comments
# In Tcl, comments are implemented using a command named "#".  There's nothing stopping you from changing that, but that's the default/convention.
# Because it's a command, it means that it only takes effect as a comment if it's at the start of a line (leading tabs and spaces ignored), or follows a [ or ; character.

proc tag_comments {} {
#	.editor.text tag remove comment 0.0 end
	# Now a proc:
	clear_tag comment

	# Explanation of the regexp here:
	# "(?:^|\n|;)" -> non-capturing group, matching either start of file, linebreak, or semicolon. Basically matches the start of a possible Tcl command.
	# "\[ \t\]*" -> any whitespace (but not linebreak) (uh, what about CR?)
	# "(#\[^\n\]*)\n" -> match the actual comment. "#" up until the next LF.
	# Bah, I don't think non-capturing groups work sensibly with [regexp -all]. :(  No, wait - just use submatch vars - they will contain the relevant indices!  This means not using "-indices".  Or "-all".  Hmm.
	# Oh, solved: use a list of variables in the foreach to match pairs, and ignore the first one!  don't even need to use non-capturing group for that, then.
	foreach {ignore index} [regexp -all -indices -inline "(?:^|\n|;)(?:\[ \t\]*)(#\[^\n\]*)\n" [get_all]] {
	#	puts "$ignore $index"
		set start [lindex $index 0]
		set end [expr {[lindex $index 1] + 1}]
		.editor.text tag add comment "1.0 + $start chars" "1.0 + $end chars"
	}
}



# Strings:

# Well, everything is a string in Tcl, but strings allowing substitutions are written in double-quotes.
# TODO: handle backslashes and things.
proc tag_strings {} {
	clear_tag string
	foreach index [regexp -all -indices -inline "\"\[^\"\]*\"" [get_all]] {
		set start [lindex $index 0]
		set end [expr {[lindex $index 1] + 1}]
		.editor.text tag add string "1.0 + $start chars" "1.0 + $end chars"
	}
}


# Again, Tcl doesn't really have keywords, but certain commands are predefined and standard:
proc tag_keywords {} {
	clear_tag keyword
	foreach index [regexp -all -indices -inline {eval|exec|exit|expr|foreach|package|proc|puts|require|set} [get_all]] {
		set start [lindex $index 0]
		set end [expr {[lindex $index 1] + 1}]
		.editor.text tag add keyword "1.0 + $start chars" "1.0 + $end chars"
	}
}

# Variable references.  Again, we can't catch all of them ("set var" is the same as "$var", for instance).
#proc tag_variables {} {
#	clear_tag variable
#}

# Probably quite important in Tcl are the brackets.  Perhaps bold for these?
# TODO

