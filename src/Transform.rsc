module Transform

import Syntax;
import Resolve;
import AST;
import IO;

/* 
 * Transforming QL forms
 */
 
 
AForm flatten(AForm f) {
  return form(f.name, flattenQ(f.questions, boolean(true))); 
}

list[AQuestion] flattenQ(list[AQuestion] questions, AExpr expr){

  list[AQuestion] newQuestions = [];
  for(AQuestion q <- questions){
    if(q is qnormal || q is qcomputed) newQuestions += qifthen(expr, [q]);
    if(q is qifthen || q is qifthenelse) {
    	if(expr != boolean(true))
			q.expr = and(q.expr, expr);    	
    	
    	newQuestions += flattenQ(q.questions, q.expr);
    }
    if(q is qifthenelse){
     newQuestions += flattenQ(q.questions2, negation(q.expr));
    }
  }
  return newQuestions; 
}

 

