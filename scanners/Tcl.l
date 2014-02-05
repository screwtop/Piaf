	int num_lines = 0, num_words = 0, start_char = 0, end_char = 0;

%%
\n	num_lines++; ++start_char;
#.*\n	end_char = start_char + strlen(yytext); printf("comment	%d	%d\n", start_char, end_char); fflush(stdout); start_char = end_char;
\{|\}|\[|\]|;|::	end_char = start_char + strlen(yytext); printf("symbol	%d	%d\n", start_char, end_char); fflush(stdout); start_char = end_char;
$[:A-Za-z0-9_]*	end_char = start_char + strlen(yytext); printf("variable	%d	%d\n", start_char, end_char); fflush(stdout); start_char = end_char;
\"[^\"]*\"	end_char = start_char + strlen(yytext); printf("string	%d	%d\n", start_char, end_char); fflush(stdout); start_char = end_char;
after|append|apply|array|bell|binary|bind|bindtags|break|button|canvas|case|catch|cd|chan|checkbutton|checkmem|clipboard|close|concat|continue|coroutine|destroy|dict|encoding|entry|eof|error|eval|evalstats|event|exec|exit|expr|fblocked|fconfigure|fcopy|file|fileevent|flush|focus|font|for|foreach|format|frame|gets|glob|global|grab|grid|if|image|incr|info|interp|join|label|labelframe|lappend|lassign|lcount|lindex|linsert|list|listbox|llength|lmap|load|lower|lrange|lrepeat|lreplace|lreverse|lsearch|lset|lsort|memory|menu|menubutton|message|namespace|open|option|pack|package|panedwindow|pid|place|proc|puts|pwd|radiobutton|raise|read|regexp|regsub|rename|return|scale|scan|scrollbar|seek|selection|send|set|socket|source|spinbox|split|string|subst|switch|tailcall|tell|text|throw|time|tk|tkwait|toplevel|trace|try|unload|unset|update|uplevel|upvar|variable|vwait|while|winfo|wm|yield|yieldto|zlib	end_char = start_char + strlen(yytext); printf("keyword	%d	%d\n", start_char, end_char); fflush(stdout); start_char = end_char;
[-A-Za-z0-9_]+	++num_words; start_char += strlen(yytext);
.	++start_char;
%%
main()
{
	yylex();
//	printf( "comment	1	5\n" ); fflush(stdout);
//	printf("keyword	8	10\n"); fflush(stdout);
//	printf("symbol	15	16\n"); fflush(stdout);
}

