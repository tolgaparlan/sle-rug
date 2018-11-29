module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;

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
  return form("", [], src=f@\loc); 
}

AQuestion cst2ast(Question q) {
  switch(q){
  	case (Question) `<Id x>:<Type t>`: return 
  	default: throw "Unhandled Question <q>";
  }
  
}

AType cst2ast((Type)`<Id x>`) = ref("<x>", src=x@loc);

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref("<x>", src=x@\loc);
    case (Expr)`<Bool x>`: return ref("<x>", src=x@\loc);
    case (Expr)`<Int x>`: return ref("<x>", src=x@\loc);
    case (Expr)`!<Expr e1>`: return !expr(e1);
    case (Expr)`<Expr e1>||<Expr e2>`: return (cst2ast(e1) || cst2ast(e2));
    case (Expr)`<Expr e1>&&<Expr e2>`: return (cst2ast(e1) && cst2ast(e2));
    case (Expr)`<Expr e1>==<Expr e2>`: return (cst2ast(e1) == cst2ast(e2));
    case (Expr)`<Expr e1>!=<Expr e2>`: return (cst2ast(e1) != cst2ast(e2));
    case (Expr)`<Expr e1>\><Expr e2>`: return (cst2ast(e1) > cst2ast(e2));
    case (Expr)`<Expr e1>\<<Expr e2>`: return (cst2ast(e1) < cst2ast(e2));
    case (Expr)`<Expr e1>\>=<Expr e2>`: return (cst2ast(e1) >= cst2ast(e2));
    case (Expr)`<Expr e1>\<=<Expr e2>`: return (cst2ast(e1) <= cst2ast(e2));
    case (Expr)`<Expr e1>+<Expr e2>`: return (cst2ast(e1) + cst2ast(e2));
    case (Expr)`<Expr e1>-<Expr e2>`: return (cst2ast(e1) - cst2ast(e2));
    case (Expr)`<Expr e1>*<Expr e2>`: return (cst2ast(e1) * cst2ast(e2));
    case (Expr)`<Expr e1>/<Expr e2>`: return (cst2ast(e1) / cst2ast(e2));
    
    default: throw "Unhandled expression: <e>";
  }
}
