# Lexical scanner for Tcl/Tk code for Piaf.

# TODO: don't call "get_all" for every single thing - just do it once, store it in a variable, and have the various scanners perform their work on that.
# TODO: longer term, run all this in a background process, so that the GUI will remain responsive no matter how big the file or how complex the language scanner.  This might mean having to stream the editor buffer (line by line? character by character?) - bringing the further complication that the scanner might not ever have an exact copy of the buffer in its curent state (nonatomic).

# It might make sense to import keywords etc. into the dictionary automatically as well when the language scanner is loaded (but how to remove them afterwards? - might have to start afresh and load the dictionary again).

# Will start with something simple: comments
# In Tcl, comments are implemented using a command named "#".  There's nothing stopping you from changing that, but that's the default/convention.
# Because it's a command, it means that it only takes effect as a comment if it's at the start of a line (leading tabs and spaces ignored), or follows a [ or ; character.
#set ::scanner_regexp(comment) "(?:^|\n|;)(?:\[ \t\]*)(#\[^\n\]*)(?:\n)"
#set ::scanner_regexp(comment) "(?:^|\n|;)(?:\[ \t\]*)(#\[^\n\]*)(?:\n|$)"	;# Improved to include comment at EOF
#set ::scanner_regexp(comment) "(?:^|\n|;)(?:\[ \t\]*)(#(?:\\\\\n|\[^\n\])*?)(?:\n|$)"	;# Improved to extend comments across backslash-continued linebreaks.
set ::scanner_regexp(comment) "(?:^|\n|;|\[)(?:\[ \t\]*)(#(?:\\\\\n|\[^\n\])*?)(?:\n|$)"	;# Improved to include comments after "["


# Strings:

# Well, everything is a string in Tcl, but strings allowing substitutions are written in double-quotes.
# TODO: handle backslashes and things.  Strings can span lines.
# TODO: don't match strings inside comments.
set ::scanner_regexp(string) "\"\[^\"\]*\""


# Again, Tcl doesn't really have keywords, but certain commands and their arguments are predefined and standard:
# join [lsort [info commands]] |
set ::scanner_regexp(keyword) {LoadBLT|after|append|apply|array|auto_execok|auto_import|auto_load|auto_load_index|auto_mkindex|auto_mkindex_old|auto_qualify|auto_reset|bell|binary|bind|bindtags|break|button|canvas|capture|case|catch|cd|chan|checkbutton|clipboard|clock|close|concat|continue|destroy|dict|encoding|entry|eof|error|eval|event|exec|exit|expr|fblocked|fconfigure|fcopy|file|fileevent|flush|focus|font|for|foreach|format|frame|gets|glob|global|grab|grid|histogram|history|if|image|incr|info|interp|join|label|labelframe|lappend|lassign|lcount|lindex|linsert|list|listbox|llength|load|lower|lrange|lrepeat|lreplace|lreverse|lsearch|lset|lsort|map|match|mean|menu|menubutton|message|namespace|open|option|pack|package|panedwindow|pid|pkg_mkIndex|place|prettify|proc|puts|pwd|radiobutton|raise|rate|rate_histogram|read|regexp|regsub|rename|repeat|return|scale|scan|scrollbar|seek|selection|send|set|shuffle|sleep|slurp|socket|source|spinbox|split|string|subst|sum|sum2|switch|system|tclLog|tclPkgSetup|tclPkgUnknown|tcl_findLibrary|tclgrep|tell|text|time|time_histogram|tk|tk_chooseColor|tk_chooseDirectory|tk_getOpenFile|tk_getSaveFile|tk_menuSetFocus|tk_messageBox|tk_popup|tk_textCopy|tk_textCut|tk_textPaste|tkwait|toplevel|trace|unknown|unload|unset|update|uplevel|upvar|variable|vwait|while|winfo|wm}



# Variable references.  Again, we can't catch all of them ("set var" is the same as "$var", for instance).
#proc tag_variables {} {
#	clear_tag variable
#}

# Probably quite important in Tcl are the brackets.  Tcl has extremely minimal syntax; this is about it.  Perhaps bold for these?
# TODO: Remember also that a backslash can continue a line (i.e. "\\\n" does not terminate a command.)
# NOTE: remember that braces inside comments ARE significant because they are actually part of the core syntax.
set ::scanner_regexp(symbol) {\[|\]|\{|\}|;|$}


