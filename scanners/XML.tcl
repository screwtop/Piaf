# Let's have a crack at XML syntax highlighting.  Should we use TDOM somehow? http://wiki.tcl.tk/8984
# Also, how well will XML fit into the "literals keywords operators..." generic model?  Maybe call every element a keyword?  And <, >, /, =, etc. symbols?

#package require tdom


# What about these special headers?:
# <?xml version='1.0' encoding='UTF-8'?>
#set ::scanner_regexp(comment) {<\?.*\?>}	;# Not really right, I realise, but might be close enough in most cases.

# Note that attribute values can be delimited by ' or " (or nothing, even?).

# Comments, e.g. <!--COMMENT-->
set ::scanner_regexp(comment) {<!--.*?(?:-->)?}	;# Simple first attempt
set ::scanner_regexp(comment) {<!--(?:[^-][^-][^>])*(?:-->)?}	;# Not quite right, but getting fairly close.  Matches incomplete comments, but suffers from strange cycling of end of the match within the trailing "-->"
set ::scanner_regexp(comment) {<!--.*?-->}	;# This'll do for now...

# Delimited strings, most commonly seen in attribute values.
set ::scanner_regexp(string) {".*?"}	;# Super-naive
#set ::scanner_regexp(string) {(?:<)(?:[^>]+?)(['"].*?['"])}	;# Again, a bit hokey, but close.  Only matches the first string in a tag.  How do we not match these inside comments?  Maybe ignore the single quotes for now...


# Element names (inside tags):
#set ::scanner_regexp(identifier) {<.*?/?>}	;# Very basic try
#set ::scanner_regexp(literal) {(?:<)(.*?)(?:/?>)}	;# Just the text inside the tags
#set ::scanner_regexp(TEST) {(?:</?)([^ /]+[^>]*?)(?:/?>)}	;# Not quite right but getting close
set ::scanner_regexp(identifier) {(?:</?)([^ /\t\n>]+?)}	;# Not too terrible

# XML has only 5 character entity references (cf. HTML's bazillion):
set ::scanner_regexp(keyword) {&amp;|&gt;|&lt;|&apos;|&quot;}

set ::scanner_regexp(symbol) {<|>|/|=|\?}

