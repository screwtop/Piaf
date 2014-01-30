# Various settings for Piaf text editor
# Can be overridden by those in ~/.piaf/settings.tcl

# Font settings first:
set ::font "LetterGothic12Pitch 10"
set ::fixed_gui_font "LetterGothic12Pitch 8"
set ::line_padding 3	;# Pixels, both above and below each line.

# Colour scheme:
set ::void_colour black	;# The colour of no text
set ::background_colour #202020	;# Background colour of the text extent
set ::text_colour white
set ::selectbackground_colour #FFFF80
set ::insertbackground_colour #00FF00
set ::current_line_background_colour #404040
#set ::current_line_foreground_colour $::text_colour

# Preferences for lexical highlighting:
set ::comment_foreground_colour #87ceeb
set ::string_foreground_colour #ffa0a0
set ::keyword_foreground_colour #f0e68c
set ::keyword_font "$::font bold"
set ::literal_foreground_colour #98fb98
# and specific colour for numeric literals?
set ::identifier_foreground_colour #ff9966

set ::highlight_interval_ms 5000	;# Long interval while testing



set ::browser firefox

# Spell-checking stuff:
set ::dictionary_file /usr/share/dict/words
set ::misspelled_foreground_colour #ff8080
# or maybe just:
# set "-foreground white -background red -underline true"
# and then you can set whatever additional properties there
set ::spellcheck_interval_ms 5000	;# Not yet honoured







