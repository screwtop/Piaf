# Text processing functions for Edita

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


# Randomly permute characters in a selection

# Randomly permute lines in a selection

# Tabs to spaces
proc ::piaf::transform::tabs_to_spaces {s} {string map {"\t" "    "} $s}

# Spaces to tabs
proc ::piaf::transform::spaces_to_tabs {s} {string map {"    " "\t"} $s}

# Remove trailing whitespace
proc ::piaf::transform::remove_trailing_whitespace {s} {regsub -all {[\t ]+\n} $s "\n"}

# Normalise/collapse whitespace
#string map {"\n" " " "\t" " "} 

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

# Smarten quotes

# Add quotes

# Remove punctuation

# Zap gremlins"

# rot-13, why not? :)
proc ::piaf::transform::rot13 {s} {
	string map [list A N B O C P D Q E R F S G T H U I V J W K X L Y M Z N A O B P C Q D R E S F T G U H V I W J X K Y L Z M a n b o c p d q e r f s g t h u i v j w k x l y m z n a o b p c q d r e s f t g u h v i w j x k y l z m] $s
}


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


