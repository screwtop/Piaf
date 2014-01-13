# Main menu bar:
menu .menubar -type menubar
.menubar configure -borderwidth 0 -activeborderwidth 0
pack .menubar -side top -fill x

# File menu:
menu .menubar.file
	.menubar.file add command -label "New" -command new
	.menubar.file add command -label "Open…" -command prompt_open_file
	.menubar.file add command -label "Insert" -command {}	;# "load $filename"
	.menubar.file add command -label "Save as…" -command prompt_save_as
	.menubar.file add command -label "Save" -command save
	.menubar.file add command -label "Save a Copy as…" -command prompt_save_to
	.menubar.file add command -label "Reload" -command reload	;# TODO: confirm? or just support undo? ;)
	.menubar.file add command -label "Close" -command close_file
	.menubar.file add separator
	.menubar.file add command -label "Exit" -command exit	;# TODO: nicer anti-lose-work exit routine
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
.menubar add cascade -label "Search" -menu .menubar.search


# Tabular menu, to assist in creating multi-range sel tags for tabular blocks?  Mark Start, Mark End, etc.?
# Or mabye a Select/Selection or Mark menu?  For commands like Mark Matching..., Mark Lines Matching... as well as tabular operations?  Selection Invert?  Select None?
menu .menubar.select
	.menubar.select add command -label "All" -command select_all
	.menubar.select add command -label "None" -command {}
	.menubar.select add command -label "Invert Selection" -command {}
	.menubar.select add command -label "Text Matching…" -command {}
	.menubar.select add command -label "Lines Matching…" -command {}
.menubar add cascade -label "Select" -menu .menubar.select -underline 0


# Transform menu:
menu .menubar.transform
	.menubar.transform add command -label "Indent" -command {transform_selection ::piaf::transform::indent}
	.menubar.transform add command -label "Case > Upper" -command {transform_selection ::piaf::transform::uppercase}
	.menubar.transform add command -label "Case > Lower" -command {transform_selection ::piaf::transform::lowercase}
	.menubar.transform add command -label "Linebreaks > CR" -command {transform_selection ::piaf::transform::crlinebreaks}
	.menubar.transform add command -label "Linebreaks > LF" -command {transform_selection ::piaf::transform::lflinebreaks}
	.menubar.transform add command -label "Linebreaks > CRLF" -command {transform_selection ::piaf::transform::crlflinebreaks}
	.menubar.transform add command -label "Rot-13" -command {transform_selection ::piaf::transform::rot13}
	.menubar.transform add command -label "Sort" -command {transform_selection ::piaf::transform::sort}
	.menubar.transform add command -label "Reverse" -command {transform_selection ::piaf::transform::reverse}
	.menubar.transform add command -label "Unwrap" -command {transform_selection ::piaf::transform::unwrap}
	.menubar.transform add command -label "Whitespace: Remove Trailing" -command {transform_selection ::piaf::transform::removetrailingwhitespace}
.menubar add cascade -label "Transform" -menu .menubar.transform -underline 0


# Language menu, for programming languages as well as spelling and grammar stuff.
menu .menubar.language
	.menubar.language add command -label "Check Spelling" -command {}
#	.menubar.language add command -label "" -command {}
.menubar add cascade -label "Language" -menu .menubar.language -underline 0

# Window/Files/Buffer menu
menu .menubar.window
.menubar add cascade -label "Window" -menu .menubar.window -underline 0



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

	.popup_menu add cascade -label "Transform" -menu .popup_menu.transform


# TODO: Transform submenu for uppercase, lowercase, init caps, reverse, sort



