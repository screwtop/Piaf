# Printing, why not?

# Could just rely on enscript for this I guess..will it handle UTF-8? Not according to the man page.  Can we inject a UTF-8-to-ASCII filter?  Enscript does have filters for lexical highlighing as well, BTW.
# If we wanted to get fancy, we could create a print setup dialog

# TODO: send via e-mail would be another likely output option.  Implement.


# TODO: handle a whole bunch of args, such as portrait/landscape, n-up, page size, printer, print to file (PS/PDF), etc., etc..
proc print {} {
	set ::status Printing...

	# Write out temporary file:

	set temp_file_basename /tmp/piaf_[pid]_print
	# That's obviously rather unix-centric!  In 8.6, you can call [file tempfile] to get a writeable temporary file.

	set file [open $temp_file_basename.txt w]
	puts -nonewline $file [get_all]
	close $file; unset file

	# Pass it to enscript for printing:
	# Annoyingly, there doesn't seem to be provision in the enscriptrc for setting the default body text and heading fonts!  Likewise the baselineskip.
	# Getting custom fonts supported required a little work:
	# Find Type1 font files.  Run "mkafmmap *.afm" there.
	# Create/edit ~/.enscriptrc and add "AFMPath: /usr/share/fonts/type1:/usr/share/enscript/afm" or whatever.
	# TODO: factor out font settings into settings.tcl.  Note that these fonts are PostScript font names, and may not match the system font names or filenames.
	# TODO: detect and report "lpr: Error - no default destination available." errors (and suggest setting PRINTER and/or LPDEST).  But ignore "WARNING: gnome-keyring" errors.
	exec enscript --media=A4 --font=LetterGothic12PitchBT-Roman@9 --header-font=LetterGothic-Slanted@6 --download-font=LetterGothic12PitchBT-Roman --baselineskip=3 --mark-wrapped-lines=arrow --word-wrap -DDuplex:true $temp_file_basename.txt

	# For print to PS and PDF files:
	catch {exec enscript --media=A4 --font=LetterGothic12PitchBT-Roman@9 --header-font=LetterGothic-Slanted@6 --download-font=LetterGothic12PitchBT-Roman --baselineskip=3 --mark-wrapped-lines=arrow --word-wrap --output=$temp_file_basename.ps $temp_file_basename.txt}
	set ::status "Creating PDF..."
	exec ps2pdf $temp_file_basename.ps $temp_file_basename.pdf
	exec acroread $temp_file_basename.pdf &

	# Delete the temporary text file:
	file delete $temp_file_basename
	unset temp_file_basename

	set ::status Ready
}

