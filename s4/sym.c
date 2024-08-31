#include <u.h>
#include <libc.h>
#include "dat.h"
#include "fns.h"

static Symbol *symtab;

Symbol *
install(char *s, int t, double v)
{
	Symbol *sym;

	sym = emalloc(sizeof(Symbol));
	sym->name = strdup(s);
	sym->type = t;
	sym->u.val = v;
	sym->next = symtab;
	symtab = sym;
	return sym;
}

Symbol *
lookup(char *s)
{
	Symbol *sym;

	for(sym = symtab; sym != nil; sym = sym->next)
		if(strcmp(sym->name, s) == 0)
			return sym;
	return nil;
}
