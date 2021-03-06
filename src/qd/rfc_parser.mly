%{
open Rfc_ast

let ectr = ref 0
%}

%token SEMCOL FULCOL
%token LBRACE RBRACE
%token LBRACK RBRACK
%token LPAREN RPAREN
%token LT     GT

%token COMMA EQUALS DOTDOT EOF
%token STRUCT ENUM
%token SELECT CASE DEFAULT
%token IF ELSE
%token ABSTRACT

%token <string>  ATTRIBUTE
%token <string>  TYPE
%token <string>  CMMNT
%token <string>  LITERAL
%token <int>     INT

%start <Rfc_ast.prog> prog
%%

prog:
	| g = list(gemstone); EOF; { g }
;

attrlist:
	| a = ATTRIBUTE; t=attrlist { a :: t }
	| {[]}
;

gemstone:
	| ENUM; a=attrlist; LBRACE; enum = separated_list(COMMA, enum_field); RBRACE; t = TYPE; SEMCOL;
		{ ectr := 0; Enum(a, enum, t) }
	| STRUCT; a = attrlist; LBRACE; fields = list(struct_field); RBRACE; t = TYPE; SEMCOL;
		{ Struct(a, fields, t) }
        | ABSTRACT; a=attrlist; t = TYPE; EQUALS; dn = LITERAL; LT; min = INT; DOTDOT; max = INT; GT
          { Abstract (a, dn, min, max, t) }
	| t = struct_field; { Typedef(t) }
;

vector_repr:
  | {None}
	| FULCOL; t = TYPE; {Some t}

vector:
	|	{ VectorNone }
	| LBRACK; l = INT; RBRACK; { VectorFixed(l) }
	| LBRACK; s = TYPE; RBRACK;	{ VectorSymbolic(s) }
	| LT; max = INT; orepr = vector_repr; GT; {VectorRange(0, max, orepr)}
	| LT; min = INT; DOTDOT; max = INT; orepr = vector_repr; GT; {VectorRange(min, max, orepr)}
	| LBRACE; k = INT; RBRACE; {VectorFixedCount(k)}
	| LBRACE; min = INT; DOTDOT; max = INT; orepr = vector_repr; RBRACE; {VectorCount(min,max,orepr)}
;

enum_field:
	| e = TYPE {let c = !ectr in incr ectr; EnumFieldSimple(e, c)}
	| e = TYPE; LPAREN; l = INT; RPAREN; { EnumFieldSimple(e, l) }
	| e = TYPE; LPAREN; a = INT; DOTDOT; b = INT; RPAREN
		{ EnumFieldRange(e, a, b) }
	| LPAREN; l = INT; RPAREN; { EnumFieldAnonymous(l) }
;

default_val:
	| { None }
	| EQUALS l = INT { Some [l] }
	| EQUALS LBRACE vl = separated_list(COMMA, INT) RBRACE { Some vl }
	| EQUALS e = TYPE; LPAREN; l = INT; RPAREN { Some  [l] }

struct_field:
	|  a=attrlist; ty = field_type; n = TYPE; v = vector; dv = default_val; SEMCOL;
	  { (a, ty, n, v, dv) }

field_type:
  | t = TYPE; { TypeSimple t }
	| LPAREN; IF; n = TYPE; EQUALS; c = LITERAL; t = TYPE; ELSE; f = TYPE; RPAREN;
	  { TypeIfeq(n, c, t, f) }
	| LPAREN; IF; n = TYPE; EQUALS; c = LITERAL; t = TYPE; RPAREN;
	  { TypeIfeq(n, c, t, "Fail") }
	| SELECT; LPAREN; n = TYPE; RPAREN; LBRACE; cases = list(select_case); def = default_case; RBRACE;
	  { TypeSelect(n, cases, def) }
;

select_case:
	| CASE; e = TYPE; FULCOL; t = TYPE; SEMCOL;	{ (e,t) }
;

default_case:
  | { None }
	| DEFAULT; FULCOL; t = TYPE; SEMCOL; { Some t }
;
