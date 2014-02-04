#!/usr/bin/env wish

# The Executor is a server program for running code in an interpreter (e.g. Python, Lua, Tcl) or even compiled code(?!) and showing the output in a window.  It's a utility for my Piaf text editor (which seems to be turning into an IDE of sorts...inevitable, I guess).
# Requirements: Tcl/Tk, Expect
# TODO: investigate [chan pipe] for separating stderr and stdout.  It might be nice to colour stderr and stdout differently somehow.

package require Tk

puts [lindex $argv 0]
if {[lindex $argv 0] != ""} {
	tk appname [lindex $argv 0]
} else {
	tk appname Executor
}

wm title . [tk appname]

set ::debugging false
proc debug_message {message} {
	if {$::debugging} {puts stderr $message}
}

#pack [text .stdin] -fill both -expand true -side top
pack [text .stdout] -fill both -expand true -side left
#pack [text .stderr] -fill both -expand true -side right



# If we're going to use Expect, we don't need the callback proc, but a proc for appending some text to the standard output text widget would still be handy:

proc append_output {text} {
	.stdout mark set insert end
	.stdout insert insert $text
	.stdout see insert
	return
}


proc quit {} {
	stop_interpreter
	exit
}



# Let's just try with a Tcl shell initially (that's what I'll probably use most to begin with anyway).
# Some interactive environments provide distinctive shell prompts, which could make detecting readiness with Expect much easier.  In many cases you can even customise the prompt to a known-good distinctive string that's unlikely to be matched by accident otherwise.

package require Expect
set timeout 3
#spawn tclsh

# NOTE: if you don't [spawn] in the global context, you had better save the spawn ID for later use, or declare it global in every proc that uses it!  The variable name "spawn_id" is special.  This would explain a lot of my problems using Expect!
# Also pay great attention to the "\r" at the end of sent commands, and the need for "--" with exp_send.

proc start_interpreter {command_name} {
	global spawn_id
	spawn $command_name
	log_user 0
	# Language-specific setup, e.g. customise prompt, set "prompt" variable:
	# TODO...
	if {[regexp "tclsh" $command_name]} {
		debug_message "It's a Tcl shell!"
		set ::executor_prompt "<<EXECUTOR_PROMPT>>"
		# The first prompt will be the default Tclsh prompt:
		expect -exact "% "
		# But then we can change it:
		exp_send -- "set tcl_prompt1 {puts -nonewline <<EXECUTOR_PROMPT>>}\r"
	#	exp_send [list set tcl_prompt1 [list puts -nonewline $::executor_prompt]]
	}
}

proc stop_interpreter {} {
	global spawn_id
	catch {exp_close}
	catch {exp_wait}
}

# For use when switching languages in the editor:
proc change_interpreter {command_name} {
	stop_interpreter
	start_interpreter $command_name
}




# Tclsh echoes the commands back when it thinks it's interactive, so he have to recognise and ignore that text.  Oh, and it might be multiple lines - how would we know how much to ignore?  Can we assume it will match $code?  What about error messages?!

proc execute {code} {
	global spawn_id
	debug_message "CODE: <<$code>>"
	# Normalise code?  Was having problems with multi-line code.  For Tcl, it might be enough to replace every linebreak with a semicolon (although what about backslash continuations?!).
	exp_send -- "$code\r"
	expect {
		-exact "$code\r\n" {debug_message "ECHO: <<$code>>"; exp_continue}
		-re "^.*\r\r\n" {
			debug_message "OUTPUT: <<$expect_out(0,string)>>"
			# The output from the spawned process has lines that end in "\r\r\n"!  Weird, but true, and it's necessary to match that correctly.
			# However, we want to strip that stuff from what gets displayed in the text widget:
			append_output [string map {"\r" ""} $expect_out(0,string)]
			exp_continue
		}
		-exact $::executor_prompt {debug_message "PROMPT"; return}
		eof {debug_message "EOF"; return}
	}
}

# Hmm, this still does bad things when you send multiple lines of code. :(


