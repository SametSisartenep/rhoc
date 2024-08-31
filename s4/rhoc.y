%{
#include "dat.h"
%}
%union {
	double val;
	Symbol *sym;
}
%token	<val> NUMBER
%token	<sym> VAR CONST BLTIN UNDEF
%type	<val> expr asgn
%right	'='
%left	'+' '-'
%left	'*' '/'
%left	'%'
%right	'^'
%left	UMINUS
%%
list:	/* ε */
	| list '\n'
	| list asgn '\n'
	| list expr '\n'	{ print("\t%.8g\n", $2); }
	| list error '\n'	{ yyerrok; }
	;
asgn:	  VAR '=' expr
	{
		if($1->type == CONST)
			rterror("assignment to constant");
		$$ = $1->u.val = $3;
		$1->type = VAR;
	}
	;
expr:	  NUMBER
	| VAR
	{
		if($1->type == UNDEF)
			rterror("undefined variable");
		$$ = $1->u.val;
	}
	| asgn
	| BLTIN '(' expr ')'	{ $$ = $1->u.fn($3); }
	| '-' expr	%prec UMINUS { $$ = -$2; }
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
	| expr '^' expr 	{ $$ = pow($1, $3); }
	| expr '(' expr ')'	{ $$ = $1 * $3; }
	| '(' expr ')'		{ $$ = $2; }
	;
%%
#include <u.h>
#include <libc.h>
#include <ctype.h>
#include <bio.h>
#include "fns.h"

Biobuf *bin;
jmp_buf begin;
int lineno;
int prompt;

void *
emalloc(ulong n)
{
	void *p;

	p = malloc(n);
	if(p == nil)
		sysfatal("malloc: %r");
	memset(p, 0, n);
	setmalloctag(p, getcallerpc(&n));
	return p;
}

void
yyerror(char *msg)
{
	fprint(2, "%s at line %d\n", msg, lineno);
}

void
rterror(char *msg)
{
	fprint(2, "%s at line %d\n", msg, lineno-1);
	longjmp(begin, 0);
}

int
catch(void *ureg, char *msg)
{
	if(strncmp(msg, "sys: fp", 7) == 0){
		yyerror("floating point exception");
		notejmp(ureg, begin, 0);
	}
	return 0;
}

int
yylex(void)
{
	Symbol *s;
	char sname[256], *p;
	Rune r;

	if(prompt){
		print("%d: ", lineno);
		prompt--;
	}
	while((r = Bgetrune(bin)) == ' ' || r == '\t')
		;
	if(r == Beof)
		return 0;
	if(r == '.' || isdigitrune(r)){
		Bungetrune(bin);
		Bgetd(bin, &yylval.val);
		return NUMBER;
	}
	if(isalpharune(r)){
		p = sname;
		do{
			if(p+runelen(r) - sname >= sizeof(sname))
				return r; /* force syntax error. */
			p += runetochar(p, &r);
		}while((r = Bgetrune(bin)) != Beof &&
			(isalpharune(r) || isdigitrune(r)));
		Bungetrune(bin);
		*p = 0;
		if((s = lookup(sname)) == nil)
			s = install(sname, UNDEF, 0);
		yylval.sym = s;
		return s->type == UNDEF || s->type == CONST ? VAR : s->type;
	}
	if(r == '\n'){
		lineno++;
		prompt++;
	}
	return r;
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
	atnotify(catch, 1);
	bin = Bfdopen(0, OREAD);
	if(bin == nil)
		sysfatal("Bfdopen: %r");
	lineno++;
	prompt++;
	init();
	setjmp(begin);
	yyparse();
	Bterm(bin);
	exits(0);
}
