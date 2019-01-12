module Transform

import Resolve;
import AST;
import IO;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) {
 *       if (b) {
 *         q1: "" int;
 *       } 
 *       q2: "" int; 
 *     }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (a && b) q1: "" int;
 *     if (a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
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

 
 

