module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import IO;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  switch(f){
  	case (Form) `form <Id x> { <Question* qs> }` : return form("<x>", [ cst2ast(q) | Question q <- qs ], src=f@\loc);
  }
}

AQuestion cst2ast(Question q) {
  switch(q){
  	case (Question) `<Str s> <Id x>:<Type t>`: 
  	  return qnormal("<s>", "<x>", cst2ast(t), src=q@\loc, nameSource=x@\loc);
  	case (Question) `<Str s> <Id x>:<Type t>=<Expr e>`: 
  	  return qcomputed("<s>", "<x>", cst2ast(t),cst2ast(e), src=q@\loc, nameSource=x@\loc);
  	case (Question) `if(<Expr e>){<Question* qs>}`: 
  	  return qifthen(cst2ast(e), [ cst2ast(q) | Question q <- qs ], src=q@\loc);
  	case (Question) `if(<Expr e>){<Question* qs1>} else {<Question* qs2>}`: 
  	  return qifthenelse(cst2ast(e), [ cst2ast(q) | Question q <- qs1 ], [ cst2ast(q) | Question q <- qs2 ], src=q@\loc);
  	default: throw "Unhandled Question: <q>";
  }
}

AType cst2ast((Type)`string`) = string();
AType cst2ast((Type)`integer`) = integer();
AType cst2ast((Type)`boolean`) = boolean();

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref("<x>", src=x@\loc);
    case (Expr) `(<Expr e>)`: return cst2ast(e);
    case (Expr)`true`: return boolean(true, src=e@\loc);
    case (Expr)`false`: return boolean(false, src=e@\loc);
    case (Expr)`<Int x>`: return number(toInt("<x>"), src=x@\loc);
    case (Expr)`<Str x>`: return string("<x>"[1..-1], src=x@\loc);
    case (Expr)`<Expr e1>||<Expr e2>`: return or(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`<Expr e1>&&<Expr e2>`: return and(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`<Expr e1>==<Expr e2>`: return equal(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`<Expr e1>!=<Expr e2>`: return notequal(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`<Expr e1>\><Expr e2>`: return larger(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`<Expr e1>\<<Expr e2>`: return smaller(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`<Expr e1>\>=<Expr e2>`: return largerequal(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`<Expr e1>\<=<Expr e2>`: return smallerequal(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`<Expr e1>+<Expr e2>`: return plus(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`<Expr e1>-<Expr e2>`: return minus(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`<Expr e1>*<Expr e2>`: return mul(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`<Expr e1>/<Expr e2>`: return div(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr)`!<Expr e1>`: return negation(cst2ast(e1), src=e@\loc);
    
    default: throw "Unhandled expression: <e>";
  }
}
