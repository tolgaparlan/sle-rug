module Eval

import AST;
import Resolve;
import IO;

import CST2AST;
import ParseTree;
import Syntax;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);

// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
Value defaultValue(AType \type) {
  switch (\type) {
    case integer():
      return vint(0);
    case boolean():
      return vbool(false);
    case string():
      return vstr("");
  }
}

VEnv initialEnv(AForm f) {
	VEnv venv = ();
	for(/AQuestion q := f.questions) {
		switch(q){
			case qnormal(str _, str name, AType \type):
				venv = venv + (name: defaultValue(\type));
			case qcomputed(str _, str name, AType \type, AExpr expr):
				venv = venv + (name: defaultValue(\type));
		}
	}
    return venv;
}


// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  for(AQuestion q <- f.questions)
    venv = eval(q, inp, venv);
  return venv;
}


VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  
  switch(q) {
    case qnormal(str _, str name, AType \type):
    	if(name == inp.question)
    		venv[name] = inp.\value;
    		
    case qcomputed(str _, str name, AType \type, AExpr expr):
    	venv[name] = eval(expr, venv);
    		
    case qifthen(AExpr expr, list[AQuestion] questions):
      if(eval(expr, venv).b)
        for(AQuestion q <- questions) venv = eval(q, inp, venv);
    
    
    case qifthenelse(AExpr expr, list[AQuestion] questions, list[AQuestion] questions2):
      if(eval(cond, venv).b)
        for(AQuestion q <- questions) venv = eval(q, inp, venv);
      else
        for(AQuestion q <- questions2) venv = eval(q, inp, venv);
  }
  
  return venv; 
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(str x): return venv[x];
    
    case number(int i): return vint(i);
    case boolean(bool b): return vbool(b);
    case string(str s): return vstr(s);
    
    case div(AExpr e1, AExpr e2):
    	return vint(eval(e1, venv).n / eval(e2, venv).n);
    case mul(AExpr e1, AExpr e2):
    	return vint(eval(e1, venv).n * eval(e2, venv).n);
    case plus(AExpr e1, AExpr e2):
    	return vint(eval(e1, venv).n + eval(e2, venv).n);
    case minus(AExpr e1, AExpr e2):
    	return vint(eval(e1, venv).n - eval(e2, venv).n);
      
    case smaller(AExpr e1, AExpr e2): 
      return vbool(eval(e1, venv).n < eval(e2, venv).n);
    case smallerequal(AExpr e1, AExpr e2): 
      return vbool(eval(e1, venv).n <= eval(e2, venv).n);
    case larger(AExpr e1, AExpr e2): 
      return vbool(eval(e1, venv).n > eval(e2, venv).n);
    case largerequal(AExpr e1, AExpr e2): 
      return vbool(eval(e1, venv).n >= eval(e2, venv).n);
      
    case or(AExpr e1, AExpr e2):
    	return vbool(eval(e1, venv).b || eval(e2, venv).b);
  	case and(AExpr e1, AExpr e2):
  		return vbool(eval(e1, venv).b && eval(e2, venv).b);
  	case negation(AExpr e1):
  		return vbool(!e1.b);
  	
  	case equal(AExpr e1, AExpr e2):
  		switch (eval(e1, venv)) {
	        case vint(int n): return vbool(eval(e1, venv).n == eval(rhse2, venv).n);
	        case vstr(str s): return vbool(eval(e1, venv).s == eval(rhse2, venv).s);
	        case vbool(bool b): return vbool(eval(e1, venv).b == eval(rhse2, venv).b);
	      }
  	case notequal(AExpr e1, AExpr e2):
  		return vbool(!eval(equal(e1, e2)).b);
    
    default: throw "Unsupported expression <e>";
  }
}