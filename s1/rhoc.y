%{
#define	YYSTYPE double
%}
%token	NUMBER
%left	'+' '-'
%left	'*' '/'
%left	UNMIN
%%
list:	/* ε */
	| list '\n'
	| list expr '\n'	{ print("\t%.8g\n", $2); }
	;
expr:	  NUMBER
	| '-' expr	%prec UNMIN { $$ = -$2; }
	| expr '+' expr		{ $$ = $1 + $3; }
	| expr '-' expr 	{ $$ = $1 - $3; }
	| expr '*' expr 	{ $$ = $1 * $3; }
	| expr '/' expr 	{ $$ = $1 / $3; }
	| expr '%' expr 	{ $$ = fmod($1, $3); }
	| expr '(' expr ')'	{ $$ = $1 * $3; }
	| '(' expr ')'		{ $$ = $2; }
	;
%%
#include <u.h>
#include <libc.h>
#include <ctype.h>
#include <bio.h>

Biobuf *bin;
int lineno;
int prompt;

int yyparse(void);

void
yyerror(char *msg)
{
	fprint(2, "%s at line %d\n", msg, lineno);
}

int
yylex(void)
{
	int c;

	if(prompt){
		print("%d: ", lineno);
		prompt--;
	}
	while((c = Bgetc(bin)) == ' ' || c == '\t')
		;
	if(c == '.' || isdigit(c)){
		Bungetc(bin);
		Bgetd(bin, &yylval);
		return NUMBER;
	}
	if(c == '\n'){
		lineno++;
		prompt++;
	}
	return c;
}

void
usage(void)
{
	fprint(2, "usage: %s\n", argv0);
	exits("usage");
}

void
main(int argc, char *argv[])
{
	ARGBEGIN{
	default: usage();
	}ARGEND;
	
	if(argc > 0)
		usage();
	bin = Bfdopen(0, OREAD);
	if(bin == nil)
		sysfatal("Bfdopen: %r");
	lineno++;
	prompt++;
	yyparse();
	Bterm(bin);
	exits(0);
}
