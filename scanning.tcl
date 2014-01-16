# Common stuff for scanning/lexical highlighting/syntax colouring.
# TODO: maybe refactor so that [get_all] is called only once per pass, and the per-language scanner procs access that globally.
# TODO: file type identification and loading of an appropriate scanner (these are stored in the "scanners" directory).
# TODO: run scanners in a separate process to avoid interfering with the main GUI!
# TODO: prevent scanner-inserted tags from interfering with the file modification status.

# Some general setup first: apply colouring/highlighting preferences:
.editor.text tag configure comment -foreground $::comment_foreground_colour
.editor.text tag configure string -foreground $::string_foreground_colour
.editor.text tag configure keyword -foreground $::keyword_foreground_colour	-font $::keyword_font;# bold? that's a font attribute.

# Now, try to get the tag priority right:
.editor.text tag raise string keyword
.editor.text tag raise comment string


# Remove all ranges for the specified tag:
proc clear_tag {tag_name} {
	.editor.text tag remove $tag_name 1.0 end
}

# Maybe the main scanner would look something like:
proc tag_all {} {
	# set text [get_all]
	foreach lexical_element {comments literals strings numbers keywords operators symbols variables} {
		catch {tag_$lexical_element}	;# Some might not exist
	}
}

# Refresh the highlighting periodically.
every 500 tag_all
# TODO: How do we cancel that, if we ever want/need to turn the live highlighting off?



