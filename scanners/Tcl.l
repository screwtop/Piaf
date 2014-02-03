	int num_lines = 0, num_words = 0, start_char = 0, end_char = 0;

%%
\n	num_lines++; ++start_char;
#.*\n	end_char = start_char + strlen(yytext); printf("comment	%d	%d\n", start_char, end_char); fflush(stdout); start_char = end_char;
\{|\}|\[|\]|;|::	end_char = start_char + strlen(yytext); printf("symbol	%d	%d\n", start_char, end_char); fflush(stdout); start_char = end_char;
$[:A-Za-z0-9_]*	end_char = start_char + strlen(yytext); printf("variable	%d	%d\n", start_char, end_char); fflush(stdout); start_char = end_char;
\"[^\"]*\"	end_char = start_char + strlen(yytext); printf("string	%d	%d\n", start_char, end_char); fflush(stdout); start_char = end_char;
after|append|apply|array|auto_execok|auto_import|auto_load|auto_load_index|auto_qualify|binary|break|capture|case|catch|cd|chan|checkmem|clock|close|concat|continue|coroutine|dict|encoding|eof|error|eval|exec|exit|expr|fblocked|fconfigure|fcopy|file|fileevent|flush|for|foreach|format|gets|glob|global|histogram|history|if|incr|info|interp|join|lappend|lassign|lcount|lindex|linsert|list|llength|lmap|load|lrange|lrepeat|lreplace|lreverse|lsearch|lset|lsort|map|match|mean|memory|namespace|open|package|pid|prettify|proc|puts|pwd|rate|rate_histogram|read|regexp|regsub|rename|repeat|return|scan|seek|set|shuffle|sleep|slurp|socket|source|split|string|subst|sum|sum2|switch|system|tailcall|tclLog|tclgrep|tell|throw|time|time_histogram|trace|try|unknown|unload|unset|update|uplevel|upvar|variable|vwait|while|yield|yieldto|zlib	end_char = start_char + strlen(yytext); printf("keyword	%d	%d\n", start_char, end_char); fflush(stdout); start_char = end_char;
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
