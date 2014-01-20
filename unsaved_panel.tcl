# Pop-up panel for prompting the user for what to do if a destructive action was invoked but there are unsaved changes.


frame .unsaved -background orange -padx 3 -pady 4
# TODO: "Cancel" button (assuming the operation can always be cancelled?)
pack [button .unsaved.cancel -text "Cancel Operation" -command {set ::unsaved_condition_dealt_with cancel}] -side left

# TODO: and if there's no buffer filenames, invoke "Save As" dialog.
pack [button .unsaved.save -text "Save" -command {save; set ::unsaved_condition_dealt_with save}] -side right
pack [button .unsaved.savecopy -text "Save a Copy..." -command {prompt_save_to; set ::unsaved_condition_dealt_with save}] -side right
pack [button .unsaved.discard -text "Discard Changes" -command {set ::unsaved_condition_dealt_with discard}] -side right

# TODO: make this work (focus issue?).  Cheap workaround: bind to the Save button, which gets focus by default.
bind .unsaved.save <Key-Escape> {.unsaved.cancel flash; .unsaved.cancel invoke}

# TODO: some kind of "review changes" or at least stats would be helpful.  The user will want to know exactly what they've changed.  Maybe a built-in diff function would be handy here.



