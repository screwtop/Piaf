#!/usr/bin/wish

# The Executor is a server program for running code in an interpreter (e.g. Python, Lua, Tcl) or even compiled code(?!) and showing the output in a window.  It's a utility for my Piaf text editor (which seems to be turning into an IDE of sorts...inevitable, I guess).
# Requirements: Tcl/Tk, Expect
# TODO: investigate [chan pipe] for separating stderr and stdout.  It might be nice to colour stderr and stdout differently somehow.

package require Tk
source asyncexec.tcl

tk appname Executor
wm title . Executor

#pack [text .stdin] -fill both -expand true -side top
pack [text .stdout] -fill both -expand true -side left
#pack [text .stderr] -fill both -expand true -side right


# Receive stuff from stdout and display on GUI:
proc handle_stdout {channel} {
	if {[gets $channel line] >=0} {
	puts stderr "got <<$line>>"
		.stdout mark set insert end
		.stdout insert insert $line
		.stdout see insert
		return
	}

	if {[eof $channel]} {
		puts stderr "EOF on $channel"
		catch {close $channel}
	#	set ::scanner_closed true
		return
	}
}

# chan event $stdout readable handle_stdout


proc quit {} {
	stop_interpreter
	exit
}



# Let's just try with a Tcl shell initially (that's what I'll probably use most to begin with anyway).
# Some interactive environments provide distinctive shell prompts, which could make detecting readiness with Expect much easier.  In many cases you can even customise the prompt to a known-good distinctive string that's unlikely to be matched by accident otherwise.


proc start_interpreter {command_name} {
	# Language-specific setup, e.g. customise prompt, set "prompt" variable:
	# TODO...
	# Let's try with my asyncexec command:
	set ::interpreter_pipeline [asyncexec $command_name {} handle_stdout {}]
#	if {[regexp "tclsh" $command_name]} {
	#	set ::executor_prompt "<<EXECUTOR_PROMPT>>"
	#	exp_send "set tcl_prompt1 [list puts -nonewline $::executor_prompt]"
#		set ::executor_prompt "% "
#	}
}

proc stop_interpreter {} {
	# TODO: catches?
	catch {chan close $::interpreter_pipeline}
}

# For use when switching languages in the editor:
proc change_interpreter {command_name} {
	stop_interpreter
	start_interpreter $command_name
}


# Can we handle stderr separately?  Possibly, using Tcl 8.6's [chan pipe],  I believe.  See asyncexec.tcl for an attempt.

proc execute {code} {
	puts $::interpreter_pipeline $code
	flush $::interpreter_pipeline
}


