# http://wiki.tcl.tk/20916

package require Tk 8.5
proc main {} {
    text .text \
        -wrap word \
        -borderwidth 0 \
        -yscrollcommand [list .vsb set]
    canvas .canvas \
        -width 20 \
        -highlightthickness 0 \
        -background white
    scrollbar .vsb \
        -borderwidth 1 \
        -command [list .text yview]

    pack .vsb -side right -fill y
    pack .canvas -side left -fill y
    pack .text -side left -fill both -expand true

    # Arrange for line numbers to be redrawn when just about anything
    # happens to the text widget. This runs much faster than you might
    # think.
    trace add execution .text leave [list traceCallback .text .canvas]
    bind .text <Configure> [list traceCallback .text .canvas]

	# Line/column number widgets:
	 toplevel .lc
	pack [label .lc.line -textvariable line -width 5 -relief sunken -anchor e]
	pack [label .lc.col -textvariable column -width 5 -relief sunken -anchor e]

	# Little bitmap image to show line wrapping:
	image create bitmap wrap_bit -foreground #aac -data {
              #define wrap_width 8
              #define wrap_height 8
		static unsigned char wrap_bits[] = {
			0x02, 0x02, 0x02, 0x22, 0x62, 0xfc, 0x60, 0x20
		};
	}

	set f [open [info script] r]
	set data [read $f]
	close $f
	.text insert end $data
}


# TODO: allow selecting an entire line by clicking on the line number in the margin ().
proc traceCallback {text canvas args} {

    # only redraw if args are null (meaning we were called by a binding)
    # or called by the trace and the command could potentially change
    # the size of a line.
	set benign {mark bbox cget compare count debug dlineinfo dump get index mark peer search}
	if {[llength $args] == 0 || [lindex $args 0 1] ni $benign} {

	$canvas delete all

	set i [$text index @0,0]
        while true {
            set dline [$text dlineinfo $i]
            if {[llength $dline] == 0} break
            set height [lindex $dline 3]
            set y [lindex $dline 1]
            set cy [expr {$y + int($height/2.0)}]
            set linenum [lindex [split $i .] 0]
            $canvas create text 0 $y -anchor nw -text $linenum

			# Draw line-wrap indicators as well:
			if {[$text count -ypixels $i "$i lineend"]} {
				$canvas create image 0 [expr {$y + [lindex $dline 4] + 8}] -image wrap_bit -anchor w
			}

			set i [$text index "$i + 1 line"]
		}

	}
	if {[lindex $args 0 1] in {insert delete mark}} {
		scan [$text index insert] %d.%d ::line ::column
	}
}
main


