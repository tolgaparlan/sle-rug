module Check

import AST;
import Resolve;
import Message; // see standard library
import List;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// set[tuple[loc def, str name, str label, Type \type]]

// convert AType to Type
Type getType(AType t) {
	switch(t){
		case string(): return tstr();
		case integer(): return tint();
		case boolean(): return tbool();
	}
}

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  TEnv collection = {};
  
  for(/AQuestion q := f.questions) {
  	if(q is qnormal || q is qcomputed)
  		collection += {<q.src, q.name, q.label, getType(q.\type)>};
  }
  
  return collection; 
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] messages = {};

  for(/AQuestion q := f.questions) {
  	if(q is qnormal || q is qcomputed){
  		messages += check(q, tenv, useDef);
  	}
  }

  return messages;
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) =
	{error("Declared elsewhere with different type", q.src) | !isEmpty([1 |e <- tenv, e.name == q.name && e.\type != getType(q.\type) ])}
	+ {warning("Duplicate labels", q.src) | !isEmpty([1 | e <- tenv, e.label == q.label && e.name != q.name])}
	+ computedQuestionCheck(q, tenv, useDef);

set[Message] computedQuestionCheck(AQuestion q, TEnv tenv, UseDef useDef) {
	if(!(q is qcomputed)){
		return {};
	}
	
	return {error("Declared type differs from the expression", q.src) | typeOf(q.expr, tenv, useDef) != getType(q.\type) }
	 + check(q.expr, tenv, useDef);
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  switch (e) {
    case ref(str x, src = loc u):
      msgs += { error("Undeclared question", u) | useDef[u] == {} };
	case or(AExpr e1, AExpr e2, src = loc u):
	  msgs += { error("Or operation needs two booleans", u) | typeOf(e1, tenv, useDef) != typeOf(e2, tenv, useDef) || typeOf(e2, tenv, useDef) != tbool() };
    case and(AExpr e1, AExpr e2, src = loc u):
      msgs += { error("And operation needs two booleans", u) | typeOf(e1, tenv, useDef) != typeOf(e2, tenv, useDef) || typeOf(e2, tenv, useDef) != tbool() };
  	case equal(AExpr e1, AExpr e2, src = loc u):
  	  msgs += { error("Equals operation needs two integers", u) | typeOf(e1, tenv, useDef) != typeOf(e2, tenv, useDef) || typeOf(e2, tenv, useDef) != tint() };
    case notequal(AExpr e1, AExpr e2, src = loc u):
      msgs += { error("Not Equal operation needs two integers", u) | typeOf(e1, tenv, useDef) != typeOf(e2, tenv, useDef) || typeOf(e2, tenv, useDef) != tint() };
    case larger(AExpr e1, AExpr e2, src = loc u):
      msgs += { error("Larger operation needs two integers", u) | typeOf(e1, tenv, useDef) != typeOf(e2, tenv, useDef) || typeOf(e2, tenv, useDef) != tint() };
    case smaller(AExpr e1, AExpr e2, src = loc u):
      msgs += { error("Smaller operation needs two integers", u) | typeOf(e1, tenv, useDef) != typeOf(e2, tenv, useDef) || typeOf(e2, tenv, useDef) != tint() };
    case largerequal(AExpr e1, AExpr e2, src = loc u):
      msgs += { error("Larger or equal operation needs two integers", u) | typeOf(e1, tenv, useDef) != typeOf(e2, tenv, useDef) || typeOf(e2, tenv, useDef) != tint() };
    case smallerequal(AExpr e1, AExpr e2, src = loc u):
      msgs += { error("Smaller or equal operation needs two integers", u) | typeOf(e1, tenv, useDef) != typeOf(e2, tenv, useDef) || typeOf(e2, tenv, useDef) != tint() };
    case plus(AExpr e1, AExpr e2, src = loc u):
      msgs += { error("Plus operation needs two integers", u) | typeOf(e1, tenv, useDef) != typeOf(e2, tenv, useDef) || typeOf(e2, tenv, useDef) != tint() };
    case minus(AExpr e1, AExpr e2, src = loc u):{
      msgs += { error("Minus operation needs two integers", u) | typeOf(e1, tenv, useDef) != typeOf(e2, tenv, useDef) || typeOf(e2, tenv, useDef) != tint() };
    }
    case mul(AExpr e1, AExpr e2, src = loc u):
      msgs += { error("Multiplication operation needs two integers", u) | typeOf(e1, tenv, useDef) != typeOf(e2, tenv, useDef) || typeOf(e2, tenv, useDef) != tint() };
    case div(AExpr e1, AExpr e2, src = loc u):
      msgs += { error("Division operation needs two integers", u) | typeOf(e1, tenv, useDef) != typeOf(e2, tenv, useDef) || typeOf(e2, tenv, useDef) != tint() };
    case negation(AExpr e1, src = loc u):
      msgs += { error("Negation operation needs a boolean", u) | typeOf(e1, tenv, useDef) != tbool() };
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(str x, src = loc u):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    case boolean(bool b):
    	return tbool();
    case number(int n):
    	return tint();
    case string(str s):
    	return tstr();
    case or(AExpr e1, AExpr e2):
    	return tbool();
    case and(AExpr e1, AExpr e2):
    	return tbool();
    case equal(AExpr e1, AExpr e2):
    	return tbool();
    case notequal(AExpr e1, AExpr e2):
    	return tbool();
    case larger(AExpr e1, AExpr e2):
    	return tbool();
    case smaller(AExpr e1, AExpr e2):
    	return tbool();
    case largerequal(AExpr e1, AExpr e2):
    	return tbool();
    case smallerequal(AExpr e1, AExpr e2):
    	return tbool();
    case plus(AExpr e1, AExpr e2):
    	return tint();
    case minus(AExpr e1, AExpr e2):
    	return tint();
    case mul(AExpr e1, AExpr e2):
    	return tint();
    case div(AExpr e1, AExpr e2):
    	return tint();
    case negation(AExpr e1):
    	return tbool();
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(str x, src = loc u), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

