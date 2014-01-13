# Text processing functions for Edita

namespace eval ::edita::transform {}

# Upper-/lower-case conversions:
proc ::edita::transform::uppercase {s} {string toupper $s}
proc ::edita::transform::lowercase {s} {string tolower $s}
proc ::edita::transform::initcaps {s} {string totitle $s}
proc ::edita::transform::randomcase {s} {
}
proc ::edita::transform::reverse {s} {join [lreverse [split $s {}]] {}}

# Sort characters in alphabetical order (Unicode-aware?!):
proc ::edita::transform::sort {s} {join [lsort [split $s {}]] {}}

#sort_lines


# Randomly permute characters in a selection

# Randomly permute lines in a selection

# Tabs to spaces
proc ::edita::transform::tabstospaces {s} {string map {"\t" "    "} $s}

# Spaces to tabs
proc ::edita::transform::spacestotabs {s} {string map {"    " "\t"} $s}

# Remove trailing whitespace
proc ::edita::transform::removetrailingwhitespace {s} {regsub -all {[\t ]+\n} $s "\n"}

# Normalise/collapse whitespace
#string map {"\n" " " "\t" " "} 

proc ::edita::transform::lflinebreaks {s} {regsub -all {[\r\n]+} $s "\n"}
proc ::edita::transform::crlinebreaks {s} {regsub -all {[\r\n]+} $s "\r"}
proc ::edita::transform::crlflinebreaks {s} {regsub -all {[\r\n]+} $s "\r\n"}

# TODO: honour user preference for tabs/spaces for indenting?
# TODO: also indent the first line if the selection starts at the start of a line
# TODO: also don't add a new tab at end?  If the user selects a whole line, they probably don't want to indent the following line, even though technically they have selected the line break as well.
proc ::edita::transform::indent {s} {
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
proc ::edita::transform::rot13 {s} {
	string map [list A N B O C P D Q E R F S G T H U I V J W K X L Y M Z N A O B P C Q D R E S F T G U H V I W J X K Y L Z M a n b o c p d q e r f s g t h u i v j w k x l y m z n a o b p c q d r e s f t g u h v i w j x k y l z m] $s
}

# Generate ASCII character table/set/list
# Or should this be a command?  I think it's better as a function, even if it's not a transformation, and doesn't depend on the starting string.
# Maybe have a namespace for generator functions
namespace eval ::edita::generate {}
proc ::edita::generate::ascii {} {
	set result {}
	# Start at 33 for only the printable characters
	for {set i 33} {$i<127} {incr i} {
		append result "[format %c $i]"
#		if {$i%16==0} {append res \n}
	}
	return $result
}


# Language-specific things can maybe go in separate files
namespace eval ::edita::latex {}
# TODO: parameterise/prompt for details
# Kinda need a file browser
proc ::edita::latex::figure {} {insert {
\begin{figure}[htbp]
	\begin{center}
		\includegraphics[0.8\textwidth]{PATH}
		\label{fig:}
		\caption{}
	\end{center}
\end{figure}
}
}


