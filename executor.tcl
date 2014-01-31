#!/usr/bin/wish

package require Tk

# Server program for running code in an interpreter (e.g. Python, Lua, Tcl) or even compiled code(?!) and showing the output in a window.  A utility for my Piaf text editor (which seems to be turning into an IDE of sorts...inevitable, I guess).
# TODO: investigate [chan pipe] for separating stderr and stdout.

tk appname Executor
wm title . Executor

#pack [text .stdin] -fill both -expand true -side top
pack [text .stdout] -fill both -expand true -side left
#pack [text .stderr] -fill both -expand true -side right


# DEPRECATED:
# Receive stuff from stdout and display on GUI:
proc handle_stdout {channel} {
	if {[gets $chan line] >=0} {
	puts stderr "got <<$line>>"
		.stdout mark set insert end
		.stdout insert insert $line
		.stdout see insert
		return
	}

	if {[eof $chan]} {
		puts stderr "EOF on $chan"
		catch {close $chan}
	#	set ::scanner_closed true
		return
	}
}

# chan event $stdout readable handle_stdout




# If we're going to use Expect, we don't need the callback proc, but a proc for appending some text to the standard output text widget would still be handy:

proc append {text} {
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
package require Expect
set timeout 3
#spawn tclsh

proc start_interpreter {command_name} {
	spawn $command_name
	log_user 0
}

proc stop_interpreter {} {
	# TODO: catches?
	catch {exp_close}
	catch {exp_wait}
}





# Bleah: command echoed back..and it might be multiple lines - how would we know how much to ignore?  Can we assume it will match $code?  What about error messages?!

# Can we handle stderr separately?  Possibly, using Tcl 8.6's [chan pipe],  I believe.



proc execute {code} {
	puts stderr "CODE: <<$code>>"
	# Normalise code?  Was having problems with multi-line code.  For Tcl, it might be enough to replace every linebreak with a semicolon (although what about backslash continuations?!).
	exp_send -- "$code\r"
	expect {
		-exact "$code\r" {puts "ECHO: <<$code>>"; exp_continue}
		-re "^.*\r\n" {
			puts "OUTPUT: <<$expect_out(0,string)>>"
			append [string trim [string map {"\r" ""} $expect_out(0,string)] " \r\n\t"
			exp_continue
		}
		-exact "% " {puts PROMPT; return}
		eof {puts EOF; return}
	}
}

# Hmm, nope - still does bad things when you send multiple lines of code. :(

# Then I think this is all you need for Piaf to run code with Ctrl-Enter:
bind .editor.text <Control-Return> {send Executor {execute [get_current_line]}}
# Nope, that tries to call get_current_line on the Executor!
bind .editor.text <Control-Return> [list send Executor [list execute [get_current_line]]]
# Nope, that evaluates [get_current_line] and stores the result in the bind action!
# Maybe a new proc?
proc executor_send {code} {send Executor [list execute $code]}
bind .editor.text <Control-Return> {executor_send [get_current_line]; break}
# OK, that's looking good.
# Might be nice to advance one line too:
# If there's a selection active, send that instead of just the current line:
bind .editor.text <Control-Return> {
	if {[.editor.text tag ranges sel] != ""} {
		executor_send [get_selection]
	} else {
		executor_send [get_current_line]
		# Advance one line:
		.editor.text mark set insert "[.editor.text index insert] + 1 line"
	}
	break	;# Override existing binding
}
