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
  = qnormal(str name, AType \type)
  | qcomputed(str name, AType \type, AExpr expr)
  | qifthen(AExpr expr, list[AQuestion] questions)
  | qifthenelse(AExpr expr, list[AQuestion] questions, list[AQuestion] questions2)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(str x)
  | boolean(bool b)
  | number(int n)
  | string(str s)
  | or(AExpr e1, AExpr e2)
  | and(AExpr e1, AExpr e2)
  | equal(AExpr e1, AExpr e2)
  | notequal(AExpr e1, AExpr e2)
  | larger(AExpr e1, AExpr e2)
  | smaller(AExpr e1, AExpr e2)
  | largerequal(AExpr e1, AExpr e2)
  | smallerequal(AExpr e1, AExpr e2)
  | plus(AExpr e1, AExpr e2)
  | minus(AExpr e1, AExpr e2)
  | mul(AExpr e1, AExpr e2)
  | div(AExpr e1, AExpr e2)
  | negation(AExpr e1)
  ;

data AType(loc src = |tmp:///|)
  = string()
  | integer()
  | boolean()
  ;
