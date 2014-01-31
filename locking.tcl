# Various routines for maintaining the lock files that will tell us if a file is already open for editing in another Piaf instance.

# It would be nice to detect if another Piaf instance is already editing a file.  Let's have Piaf create a lock file with a predictable filename when it has a file open for editing.  If the file is open, the user could choose to:
# - Switch to the Piaf instance that holds the lock
# - Open the file in read-only mode
# - Give up (cancel the operation)

# TODO: some kind of interactive functionality to ask the user what to do in the event of a lock acquisition failure.  At the moment, they'll just see an error, and then things will barge ahead anyway!
# TODO: recognise other editors' lock files so we can support those too?!

# This procedure initialises a global array called ::lock_data which will hold information for writing into the lock file.
proc set_lock_data {} {
	set ::lock_data(filename) $::filename
	# date created/modified
	set ::lock_data(appname) [tk appname]
	# [info script], [info nameofexecutable]
	set ::lock_data(pwd) [pwd]
	set ::lock_data(pid) [pid]
	set ::lock_data(time) [clock seconds]
#	return
	array get ::lock_data
}

# Generate a suitably obscure filename for the lock file based on the current filename.
# Note that this will return a value regardless of whether the lock file acutally exists.  Use [locked] to check for its existence.
proc get_lock_filename {{filename ""}} {
	# Have filename default to the global ::filename value:
	if {[llength [info level 0]] < 2} {
		set filename $::filename
	}
	if {$filename != ""} {
		return [file join [file dirname $filename] "._piaf_.[file tail $filename].lck"]
	} else {
		return ""
	}
}

# Acquire a lock on the current file, by creating a lock file in the filesystem:
# Or should this be parameterised for filename to be consistent with the others?  Perhaps have the filename arg optional.
# Would it be useful/essential to also check whether the lock file is actually ours, i.e. this Piaf process?  If that's the case, then it'd be OK to go ahead.
proc lock {{filename ""}} {
	# Have filename default to the global ::filename value:
	if {[llength [info level 0]] < 2} {
		set filename $::filename
	}
	# Check if a lock file exists for the current file:
	# Should this return an error or just a true/false value so it can be checked by the caller?
	# Also, if we already hold a lock on the file, that's OK.
	if {[locked $filename]} {
		if {[lock_is_ours $filename]} {
			return true
		} else {
			return false
		#	error "File is locked ([get_lock_data $filename])"
		}
	} else {
		# No lock file, so go ahead and create it:
		set lock_file [open [get_lock_filename $filename] w]
		set_lock_data	;# Goes into array ::lock_data
		puts $lock_file [array get ::lock_data]
		close $lock_file
		return true
	}
}

# Determine whether the lock file belongs to us (in which case it's no problem and we can proceed with whatever operation we like):
proc lock_is_ours {{filename ""}} {
	# Have filename default to the global ::filename value:
	if {[llength [info level 0]] < 2} {
		set filename $::filename
	}
	if {[file exists [get_lock_filename $filename]]} {
		array set checking_lock_data [get_lock_data $filename]
		return [expr {$checking_lock_data(pid) == [pid]}]
	} else {
		return false;# or null/""?
	}
}

# Check to see if a file lock exists for the specified filename:
# Or rather, should this check if a lock exists and it's owned by a different Piaf process?
# Basically, should it be "a lock exists" or "it's locked by someone else"?
# Now that we have "lock_is_ours", it might make sense just to leave this as a "lock exists (but could be anyone's)".
proc locked {{filename ""}} {
	# Have filename default to the global ::filename value:
	if {[llength [info level 0]] < 2} {
		set filename $::filename
	}
	file exists [get_lock_filename $filename]
	# TODO: perhaps return the lock data from the file?  Or have a separate function for that detail?
}

proc get_lock_data {{filename ""}} {
	# Have filename default to the global ::filename value:
	if {[llength [info level 0]] < 2} {
		set filename $::filename
	}
	if {[locked $filename]} {
	#	array set checking_lock_data [slurp [get_lock_filename $filename]]
		# Can we return an array?!  Nope.
	#	parray checking_lock_data
	#	return $checking_lock_data
		# Maybe just return the list and let the caller array-ify it if necessary:
		return [slurp [get_lock_filename $filename]]
	}
}

# When closing a file or saving it under a new name, release the lock on the old one
# Should probably be parameterised for filename, since ::filename is probably already set to the new one.
# This should only succeed/proceed if we actually own the lock!
proc unlock {{filename ""}} {
	# Have filename default to the global ::filename value:
	if {[llength [info level 0]] < 2} {
		set filename $::filename
	}
	# Check if a lock file exists for the current file:
	if {[file exists [get_lock_filename $filename]]} {
		if {[lock_is_ours $filename]} {
			# Delete it.  Quite conceivable that this could fail - catch?!
			file delete [get_lock_filename $filename]
		} else {
			# Fail somehow.  Return false, or raise an error?
			error "unlock $filename: Lock is not ours!"
		}
	} else {
		# File apparently wasn't locked.  Error, or do nothing?
	}
	return
}

