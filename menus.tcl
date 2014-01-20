# Main menu bar:
menu .menubar -type menubar
.menubar configure -borderwidth 0 -activeborderwidth 0
pack .menubar -side top -fill x

# File menu:
menu .menubar.file
	.menubar.file add command -label "New" -command new
	.menubar.file add command -label "Open…" -command prompt_open_file
	.menubar.file add command -label "Insert…" -command prompt_load_file	;# Cf. prompt_open_file
	.menubar.file add command -label "Save as…" -command prompt_save_as
	.menubar.file add command -label "Save" -command save
	.menubar.file add command -label "Save a Copy as…" -command prompt_save_to
	.menubar.file add command -label "Reload" -command reload	;# TODO: confirm? or just support undo? ;)
	.menubar.file add command -label "Close" -command close_file
	.menubar.file add separator
	.menubar.file add command -label "Exit" -command quit	;# TODO: nicer anti-lose-work exit routine
.menubar add cascade -label File -menu .menubar.file -underline 0

# Edit menu:
menu .menubar.edit
	.menubar.edit add command -label "Undo" -command undo
	.menubar.edit add command -label "Redo" -command redo
	.menubar.edit add separator
	.menubar.edit add command -label "Select All" -command select_all -underline 7
	.menubar.edit add command -label "Cut" -command cut
	.menubar.edit add command -label "Copy" -command copy
	.menubar.edit add command -label "Paste" -command paste
.menubar add cascade -label Edit -menu .menubar.edit -underline 0

# Insert menu:
menu .menubar.insert
.menubar.insert add command -label "LaTeX Figure" -command ::piaf::latex::figure
.menubar add cascade -label "Insert" -menu .menubar.insert -underline 0
	# Unicode submenu;
	menu .menubar.insert.unicode
	.menubar.insert.unicode add command -label "Left Single Quotation Mark (\u2018)" -command {insert "\u2018"}
	.menubar.insert.unicode add command -label "Right Single Quotation Mark (\u2019)" -command {insert "\u2019"}
	.menubar.insert.unicode add command -label "Left Double Quotation Mark (\u201c)" -command {insert "\u201c"}
	.menubar.insert.unicode add command -label "Right Double Quotation Mark (\u201d)" -command {insert "\u201d"}
	.menubar.insert.unicode add command -label "Horizontal Ellipsis (\u2026)" -command {insert "\u2026"}
	.menubar.insert.unicode add command -label "Paragraph symbol (\u204b)" -command {insert "\u204b"}
	.menubar.insert.unicode add command -label "Section symbol (\u00a7)" -command {insert "\u00a7"}
	.menubar.insert.unicode add command -label "Return symbol (\u23ce)" -command {insert "\u23ce"}
	.menubar.insert.unicode add command -label "Smiling Face (\u263a)" -command {insert "\u263a"}
	.menubar.insert.unicode add command -label "CR symbol (\u240d)" -command {insert "\u240d"}
	.menubar.insert.unicode add command -label "LF symbol (\u240a)" -command {insert "\u240a"}
	.menubar.insert.unicode add command -label "Delete symbol (\u2421)" -command {insert "\u2421"}
	.menubar.insert add cascade -label "Character" -menu .menubar.insert.unicode


# Search menu? Or perhaps a more general Navigate menu?
menu .menubar.search
# Disabled for now:
#.menubar add cascade -label "Search" -menu .menubar.search


# Tabular menu, to assist in creating multi-range sel tags for tabular blocks?  Mark Start, Mark End, etc.?
# Or mabye a Select/Selection or Mark menu?  For commands like Mark Matching..., Mark Lines Matching... as well as tabular operations?  Selection Invert?  Select None?
menu .menubar.select
	.menubar.select add command -label "All" -command select_all
	.menubar.select add command -label "None" -command select_none
#	.menubar.select add command -label "Invert Selection" -command {}
#	.menubar.select add command -label "Text Matching…" -command {}	;# This could probably just loop through existing code
#	.menubar.select add command -label "Lines Matching…" -command {}
.menubar add cascade -label "Select" -menu .menubar.select -underline 0


# Transform menu:
menu .menubar.transform
	menu .menubar.transform.convert
		.menubar.transform.convert add command -label "Binary to decimal" -command {transform_selection ::piaf::transform::bin_to_dec}
		.menubar.transform.convert add command -label "Binary string to data" -command {transform_selection ::piaf::transform::bin_to_char}
		.menubar.transform.convert add separator
		.menubar.transform.convert add command -label "Decimal to binary" -command {transform_selection ::piaf::transform::dec_to_bin}
		.menubar.transform.convert add command -label "Decimal to octal" -command {transform_selection ::piaf::transform::dec_to_oct}
		.menubar.transform.convert add command -label "Decimal to hexadecimal" -command {transform_selection ::piaf::transform::dec_to_hex}
		.menubar.transform.convert add command -label "Decimal to Unicode" -command {transform_selection ::piaf::transform::dec_to_unicode}
		.menubar.transform.convert add separator
		.menubar.transform.convert add command -label "Hexadecimal to decimal" -command {transform_selection ::piaf::transform::hex_to_dec}
		.menubar.transform.convert add command -label "Hexadecimal to Unicode" -command {transform_selection ::piaf::transform::hex_to_unicode}
		.menubar.transform.convert add separator
		.menubar.transform.convert add command -label "Octal to decimal" -command {transform_selection ::piaf::transform::oct_to_dec}
		.menubar.transform.convert add separator
		.menubar.transform.convert add command -label "Unicode to decimal" -command {transform_selection ::piaf::transform::unicode_to_dec}
		.menubar.transform.convert add command -label "Unicode to hexadecimal" -command {transform_selection ::piaf::transform::unicode_to_hex}
		.menubar.transform.convert add separator
		.menubar.transform.convert add command -label "Data to binary string" -command {transform_selection ::piaf::transform::char_to_bin}
	.menubar.transform add cascade -label "Convert" -menu .menubar.transform.convert

	.menubar.transform add separator
	.menubar.transform add command -label "Indent" -command {transform_selection ::piaf::transform::indent}
	.menubar.transform add command -label "Case > UPPER" -command {transform_selection ::piaf::transform::uppercase}
	.menubar.transform add command -label "Case > lower" -command {transform_selection ::piaf::transform::lowercase}
	.menubar.transform add command -label "Collapse whitespace" -command {transform_selection ::piaf::transform::collapse_whitespace}
	.menubar.transform add command -label "Linebreaks > CR" -command {transform_selection ::piaf::transform::crlinebreaks}
	.menubar.transform add command -label "Linebreaks > LF" -command {transform_selection ::piaf::transform::lflinebreaks}
	.menubar.transform add command -label "Linebreaks > CRLF" -command {transform_selection ::piaf::transform::crlflinebreaks}
	.menubar.transform add command -label "Reverse chars" -command {transform_selection ::piaf::transform::reverse}
	.menubar.transform add command -label "Rot-13" -command {transform_selection ::piaf::transform::rot13}
	.menubar.transform add command -label "Sort chars" -command {transform_selection ::piaf::transform::sort}
	.menubar.transform add command -label "Sort lines" -command {transform_selection ::piaf::transform::sort_lines}
	.menubar.transform add command -label "Spaces to tabs" -command {transform_selection ::piaf::transform::spaces_to_tabs}
	.menubar.transform add command -label "Strip blank lines" -command {transform_selection ::piaf::transform::strip_blank_lines}
	.menubar.transform add command -label "Tabs to spaces" -command {transform_selection ::piaf::transform::tabs_to_spaces}
	.menubar.transform add command -label "Trim trailing whitespace" -command {transform_selection ::piaf::transform::remove_trailing_whitespace}
	.menubar.transform add command -label "Unwrap" -command {transform_selection ::piaf::transform::unwrap}
.menubar add cascade -label "Transform" -menu .menubar.transform -underline 0


# Language menu, for programming languages as well as spelling and grammar stuff.
menu .menubar.language
	.menubar.language add command -label "Check Spelling" -command spellcheck	;# Using the current active/default spellchecker
	.menubar.language add command -label "Check Spelling (Aspell)" -command spellcheck_aspell
	.menubar.language add command -label "Check Spelling (built-in)" -command spellcheck_builtin
	.menubar.language add command -label "Clear Misspellings" -command clear_spelling_errors
	# TODO: periodic spellchecking on/off
	.menubar.language add separator
	.menubar.language add command -label "Tcl" -command {source "$::binary_path/scanners/Tcl.tcl"}
	.menubar.language add command -label "XML" -command {source "$::binary_path/scanners/XML.tcl"}
.menubar add cascade -label "Language" -menu .menubar.language -underline 0


# Reference menu, with Web searches and such
menu .menubar.reference
	.menubar.reference add command -label "Search Wiktionary" -command search_wiktionary_for_selection
	.menubar.reference add command -label "Search Wikipedia" -command search_wikipedia_for_selection
	.menubar.reference add command -label "Search Google" -command search_web_for_selection
	.menubar.reference add command -label "Open URL in browser" -command open_selection_in_browser
	.menubar.reference add command -label "Evaluate in Frink" -command frink_eval

	menu .menubar.reference.frink
		.menubar.reference.frink add command -label "Terminate Frink server" -command stop_frinkserver
		.menubar.reference.frink add command -label "Start Frink server" -command start_frinkserver
	.menubar.reference add cascade -label "Frink server" -menu .menubar.reference.frink

.menubar add cascade -label "Reference" -menu .menubar.reference -underline 0


# Window/Files/Buffer menu
menu .menubar.window
# Disabled for now:
#.menubar add cascade -label "Window" -menu .menubar.window -underline 0


# Console (or more general System) menu:
menu .menubar.console
	.menubar.console add command -label "Show Console window" -command {wm deiconify .console}
	.menubar.console add command -label "Hide Console window" -command {wm withdraw .console}
.menubar add cascade -label "Console" -menu .menubar.console -underline 0





# Contextual menu for text also (with cut, copy, paste, delete/clear, mark for swap, etc.
# Don't want f***ing drag-and-drop.

menu .popup_menu
	.popup_menu add command -label "Select All" -command select_all
	.popup_menu add command -label "Copy" -command copy
	.popup_menu add command -label "Paste" -command paste
	menu .popup_menu.transform
		.popup_menu.transform add command -label "Case: Uppercase" -command {transform_selection ::piaf::transform::uppercase}
		.popup_menu.transform add command -label "Case: Lowercase" -command {transform_selection ::piaf::transform::lowercase}
		.popup_menu.transform add command -label "Indent" -command {transform_selection ::piaf::transform::indent}
		.popup_menu.transform add command -label "Reverse" -command {transform_selection ::piaf::transform::reverse}
		.popup_menu.transform add command -label "Rot-13" -command {transform_selection ::piaf::transform::rot13}
		.popup_menu.transform add command -label "Sort" -command {transform_selection ::piaf::transform::sort}

#	.popup_menu add cascade -labe "Transform" -menu .menubar.transform	;# Can we do this? i.e. share a menu among multiple cascade parents?
	.popup_menu add cascade -label "Transform" -menu .popup_menu.transform


# TODO: Transform submenu for uppercase, lowercase, init caps, reverse, sort








