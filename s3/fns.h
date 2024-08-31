int yyparse(void);

Symbol *install(char *, int, double);
Symbol *lookup(char *);
double round(double);
void init(void);
void *emalloc(ulong);
