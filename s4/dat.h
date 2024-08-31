typedef struct Symbol Symbol;
typedef struct Const Const;
typedef struct Builtin Builtin;

struct Symbol {
	char *name;
	int type;
	union {
		double val;
		double (*fn)(double);
	} u;
	Symbol *next;
};

struct Const {
	char *name;
	double val;
};

struct Builtin {
	char *name;
	double (*fn)();
};
