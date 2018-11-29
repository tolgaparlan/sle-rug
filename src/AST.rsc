module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = question(str name, AType type)
  | question(str name, Atype type, AExpr expr)
  | question(AExpr expr, list[AQuestion] questions)
  | question(AExpr expr, list[AQuestion] questions, list[AQuestion] questions2)
  ; 

data AExpr(loc src = |tmp:///|)
  = expr(AType type)
  | expr(AExpr expl, AExpr expr)
  | expr(Aexpr exp);

data AType(loc src = |tmp:///|)
  = type(str s);
