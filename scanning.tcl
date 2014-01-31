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
.editor.text tag raise sel comment	;# To keep things simple when highlighting coloured text, we just have the selection style dominate.
.editor.text tag raise TEST sel	;# For internal testing.


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

# Refresh the highlighting periodically.
# For using the external scanner processes:
set ::language "";# TODO: maybe have this in settings - could default to English.
every $::highlight_interval_ms {highlight_syntax $::language}
#every $::highlight_interval_ms tag_all
# TODO: How do we cancel that, if we ever want/need to turn the live highlighting off?



