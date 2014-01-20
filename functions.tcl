# Text processing functions for Piaf text editor

namespace eval ::piaf::transform {}

# Upper-/lower-case conversions:
proc ::piaf::transform::uppercase {s} {string toupper $s}
proc ::piaf::transform::lowercase {s} {string tolower $s}
proc ::piaf::transform::initcaps {s} {string totitle $s}
proc ::piaf::transform::randomcase {s} {
}
proc ::piaf::transform::reverse {s} {join [lreverse [split $s {}]] {}}

# Sort characters in alphabetical order (Unicode-aware?!):
proc ::piaf::transform::sort {s} {join [lsort [split $s {}]] {}}

proc ::piaf::transform::sort_lines {text} {join [lsort [split $text "\n"]] "\n"}

# Remove duplicates (implicitly sorting in the process!):
proc ::piaf::transform::remove_duplicate_characters {s} {join [lsort -unique [split $s {}]] {}}
proc ::piaf::transform::remove_duplicate_lines {text} {join [lsort -unique [split $text "\n"]] "\n"}

# Randomly permute characters in a selection

# Randomly permute lines in a selection

# Tabs to spaces
proc ::piaf::transform::tabs_to_spaces {s} {string map {"\t" "    "} $s}

# Spaces to tabs
proc ::piaf::transform::spaces_to_tabs {s} {string map {"    " "\t"} $s}

# Remove trailing whitespace
proc ::piaf::transform::remove_trailing_whitespace {s} {regsub -all {[\t ]+\n} $s "\n"}

# Strip blank lines:
# TODO: handle blank line at the start correctly
#proc ::piaf::transform::strip_blank_lines {s} {regsub -all {\n+} $s "\n"}
# TODO: maybe treat lines containing only whitespace as blank?  User could just remove trailing whitespace first, then strip blank lines.
# Here's an implementation due to DKF:
proc ::piaf::transform::strip_blank_lines {s} {regsub -all {^\n+|\n+$|(\n)+} $s {\1}}

# Normalise/collapse whitespace
proc ::piaf::transform::collapse_whitespace {s} {regsub -all "\[\r\n\t \]+" $s " "}

proc ::piaf::transform::lflinebreaks {s} {regsub -all {[\r\n]+} $s "\n"}
proc ::piaf::transform::crlinebreaks {s} {regsub -all {[\r\n]+} $s "\r"}
proc ::piaf::transform::crlflinebreaks {s} {regsub -all {[\r\n]+} $s "\r\n"}

# Unwrap lines.  Basically, remove single linebreaks (and remove double, triple, etc. linebreaks?).
# Will this match the start/end of the entire document as well?  Dang corner cases...
proc ::piaf::transform::unwrap {s} {regsub -all {([^\n])\n([^\n])} $s {\1\2}}

# TODO: honour user preference for tabs/spaces for indenting?
# TODO: also indent the first line if the selection starts at the start of a line
# TODO: also don't add a new tab at end?  If the user selects a whole line, they probably don't want to indent the following line, even though technically they have selected the line break as well.
proc ::piaf::transform::indent {s} {
	if {[lindex [split [.editor.text index sel.first] {.}] 1] == 0} {
		set s "\t$s"
	}
	# Can we just blanket trim any trailing tabs?  What if there was a trailing tab at the end of a line already?!
	string trimright [string map {"\n" "\n\t"} $s] "\t"
}

# TODO: unindent

# Smarten quotes

# Add quotes around selection

# Remove punctuation

# "Zap gremlins"

# rot-13, why not? :)
proc ::piaf::transform::rot13 {s} {
	string map [list A N B O C P D Q E R F S G T H U I V J W K X L Y M Z N A O B P C Q D R E S F T G U H V I W J X K Y L Z M a n b o c p d q e r f s g t h u i v j w k x l y m z n a o b p c q d r e s f t g u h v i w j x k y l z m] $s
}


# Find/Change AKA Search/Replace operations:

# First the simple non-regexp literal-text one:
proc ::piaf::transform::replace_all {text original replacement} {string map [list $original $replacement] $text}

# Now how to make a case-insensitive version of the same?  [string map -nocase ...] in a pinch, but it might be nice for it to retain the case for each character when doing a replacement!
proc ::piaf::transform::replace_all_case_insensitive {text original replacement} {string map -nocase [list $original $replacement] $text}

# And one that will only match "whole words"?



# Number system conversions:
# TODO: maybe make some of these more forgiving in what they'll accept...

# Trickiness here because we have to pad to a minimum number of digits for "W" (64-bit) format.
# Is 64 bits excessive?  To be really useful we'd have a dialog with length and signedness and endianness and such.  But one does often encounter binary strings longer than 32 bits (e.g. Ethernet MACs, HDD LBAs, IPv6 addresses).
proc ::piaf::transform::bin_to_dec {binary_string} {binary scan [binary format B* [format %064s $binary_string]] Wu* binary; return $binary}
proc ::piaf::transform::dec_to_bin {num} {binary scan [binary format Wu* $num] B* res; string trimleft $res 0}

# Hexadecimal:
proc ::piaf::transform::hex_to_dec {hex} {scan $hex %x}
proc ::piaf::transform::dec_to_hex {num} {return "0x[format %x $num]"}

# Octal:
proc ::piaf::transform::oct_to_dec {oct} {scan $oct %o}
proc ::piaf::transform::dec_to_oct {num} {format %o $num}

# Find Unicode code point for character (decimal):
proc ::piaf::transform::unicode_to_dec {char} {scan $char %c}
proc ::piaf::transform::unicode_to_hex {char} {return "0x[format %x [scan $char %c]]"}
# TODO: decimal and hexadecimal to Unicode character
proc ::piaf::transform::dec_to_unicode {num} {format %c $num}
#proc ::piaf::transform::hex_to_unicode {hex} {return "\u$hex"}
proc ::piaf::transform::hex_to_unicode {hex} {format %c [scan $hex %x]}

# Actual binary data:
proc ::piaf::transform::bin_to_char {binary_string} {binary format B* $binary_string}
proc ::piaf::transform::char_to_bin {char} {binary scan $char B* binary; return $binary}


# Function for shortening long filenames (primarily for use within the Piaf GUI itself, but maybe useful otherwise):
# Kinda needs an argument for maximum acceptable result length, huh?
proc abbreviate_filename {filename max_length} {
	if {[string length $filename] < $max_length} {
		return $filename
	} else {
		# TODO: something smarter!
		return "..."
	}
}


# Generate ASCII character table/set/list
# Or should this be a command?  I think it's better as a function, even if it's not a transformation, and doesn't depend on the starting string.
# Maybe have a namespace for generator functions
namespace eval ::piaf::generate {}
proc ::piaf::generate::ascii {} {
	set result {}
	# Start at 33 for only the printable characters
	for {set i 33} {$i<127} {incr i} {
		append result "[format %c $i]"
#		if {$i%16==0} {append res \n}
	}
	return $result
}


# Language-specific things can maybe go in separate files
namespace eval ::piaf::latex {}
# TODO: parameterise/prompt for details
# Kinda need a file browser
proc ::piaf::latex::figure {} {insert {
\begin{figure}[htbp]
	\begin{center}
		\includegraphics[0.8\textwidth]{PATH}
		\label{fig:}
		\caption{}
	\end{center}
\end{figure}
}
}









