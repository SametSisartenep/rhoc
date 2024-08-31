#include <u.h>
#include <libc.h>
#include "dat.h"
#include "fns.h"
#include "y.tab.h"

static Const consts[] = {
	"π",	3.14159265358979323846,
	"e",	2.71828182845904523536,
	"γ",	0.57721566490153286060,
	"DEG",	57.29577951308232087680,
	"Φ",	1.61803398874989484820,
};

static Builtin builtins[] = {
	"sin",		sin,
	"cos",		cos,
	"atan",		atan,
	"atan2",	atan2,
	"log",		log,
	"log10",	log10,
	"exp",		exp,
	"sqrt",		sqrt,
	"int",		round,
	"abs",		fabs,
};

double
round(double n)
{
	return floor(n + 0.5);
}

void
init(void)
{
	Symbol *s;
	int i;

	for(i = 0; i < nelem(consts); i++)
		install(consts[i].name, CONST, consts[i].val);
	for(i = 0; i < nelem(builtins); i++){
		s = install(builtins[i].name, BLTIN, 0);
		s->u.fn = builtins[i].fn;
	}
}
