%{
double mem[26];
%}
%union {
	double val;
	int idx;
}
%token	<val> NUMBER
%token	<idx> VAR
%type	<val> expr
%right	'='
%left	'+' '-'
%left	'*' '/'
%left	UNMIN
%%
list:	/* ε */
	| list '\n'
	| list expr '\n'	{ print("\t%.8g\n", $2); }
	| list expr ';'		{ print("\t%.8g\n", $2); }
	| list error '\n'	{ yyerrok; }
	;
expr:	  NUMBER
	| VAR			{ $$ = mem[$1]; }
	| VAR '=' expr		{ $$ = mem[$1] = $3; }
	| '-' expr	%prec UNMIN { $$ = -$2; }
	| expr '+' expr		{ $$ = $1 + $3; }
	| expr '-' expr 	{ $$ = $1 - $3; }
	| expr '*' expr 	{ $$ = $1 * $3; }
	| expr '/' expr
	{
		if($3 == 0)
			rterror("division by zero");
		$$ = $1 / $3;
	}
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
jmp_buf begin;
int lineno;
int prompt;

int yyparse(void);

void
error(char *msg, int ln)
{
	fprint(2, "%s at line %d\n", msg, ln);
}

void
yyerror(char *msg)
{
	error(msg, lineno);
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
		Bgetd(bin, &yylval.val);
		return NUMBER;
	}
	if(islower(c)){
		yylval.idx = c - 'a';
		return VAR;
	}
	if(c == '\n'){
		lineno++;
		prompt++;
	}
	return c;
}

void
rterror(char *msg)
{
	error(msg, lineno-1);
	longjmp(begin, 0);
}

int
catch(void *ureg, char *msg)
{
	if(strncmp(msg, "sys: fp", 7) == 0){
		error("floating point exception", lineno-1);
		notejmp(ureg, begin, 0);
	}
	return 0;
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
	setjmp(begin);
	atnotify(catch, 1);
	yyparse();
	Bterm(bin);
	exits(0);
}
