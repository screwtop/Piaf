	// Count chars/words/lines for Piaf
	// Output a single line consisting of the three values, separated by tabs.
	// Should we count linebreaks as characters?  Logical/physical question, essentially...
	int num_lines = 0, num_words = 0, num_chars = 0;

%%
\n	++num_lines; ++num_chars;
[-A-Za-z0-9_]+	++num_words; num_chars += strlen(yytext);
.	++num_chars;

%%
main()
{
	yylex();
	printf( "%d chars\t%d words\t%d lines\n", num_chars, num_words, num_lines );
}


