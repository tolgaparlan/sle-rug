module Compile

import AST;
import Resolve;
import lang::html5::DOM; // see standard library

import ParseTree;
import Syntax;
import CST2AST; 
import Eval;
import util::Math;
import Boolean;

import IO;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

void aaa(){
	compile(cst2ast(parse(#start[Form], |project://QL/examples/a.myql|)));
}

HTML5Node form2html(AForm f) {
	return html(
		head(
			script(src("jquery-3.3.1.min.js")),
			script(src(f.src[extension="js"].file)), 
			script(src("index.js"))),
		body(h1(f.name), form(questions2html(f.questions)), button("Submit")));
}

HTML5Node questions2html (list[AQuestion] qs){
	list[HTML5Node] nodes = [];
	for(AQuestion q <- qs){
		switch(q){
			case qnormal(str l, str n, AType t):{
				HTML5Node questionLabel = h3(l);
				HTML5Node inputBox;
				switch(t){
					case string():
						inputBox = input(name(n));
					case integer():
						inputBox = input(name(n), \type("number"));
					case boolean():
						inputBox = div([input(name(n), id(n + "-true"), \value("true"), \type("radio")),
									label(\for(n + "-true"), "True"), 
									input(name(n), id(n + "-true"), \value("false"), \type("radio")),
									label(\for(n + "-false"), "False")]);
				}
				
				nodes += div(questionLabel, inputBox);
			}
			case qcomputed(str l, str n, AType _, AExpr _):
				nodes += div(h3(l), input(name(n), readonly("readonly")));
			case qifthen(AExpr expr, list[AQuestion] questions):
				nodes += div(questions2html(q.questions), class("toggled"), about(expr2str(expr)));
			case qifthenelse(AExpr expr, list[AQuestion] questions, list[AQuestion] questions2):{
				nodes += div(questions2html(q.questions), class("toggled"), about(expr2str(expr)));
				nodes += div(questions2html(q.questions2), class("toggled"), about(expr2str(negation(expr))));
			}
		}
	}
	return div(nodes);
}

str expr2str(AExpr expr){
  switch (expr) {
    case ref(str x):
      return "(<x>)";
    case string(str s):
      return "\'" + s + "\'";
    case boolean(bool b):
      return toString(b);
    case number(int n):
      return toString(n);
	case or(AExpr e1, AExpr e2):
	  return expr2str(e1) + "||" + expr2str(e2);
    case and(AExpr e1, AExpr e2):
      return expr2str(e1) + "&&" + expr2str(e2);
    case equal(AExpr e1, AExpr e2):
  	  return expr2str(e1) + "==" + expr2str(e2);
  	case notequal(AExpr e1, AExpr e2):
	  return expr2str(e1) + "!=" + expr2str(e2);      
    case larger(AExpr e1, AExpr e2):
      return expr2str(e1) + "\>" + expr2str(e2);
    case smaller(AExpr e1, AExpr e2):
      return expr2str(e1) + "\<" + expr2str(e2);
    case largerequal(AExpr e1, AExpr e2):
      return expr2str(e1) + "\>=" + expr2str(e2);
    case smallerequal(AExpr e1, AExpr e2):
      return expr2str(e1) + "\<=" + expr2str(e2);
    case plus(AExpr e1, AExpr e2):
      return expr2str(e1) + "+" + expr2str(e2);
    case minus(AExpr e1, AExpr e2):
	  return expr2str(e1) + "-" + expr2str(e2);
    case mul(AExpr e1, AExpr e2):
      return expr2str(e1) + "*" + expr2str(e2);  
    case div(AExpr e1, AExpr e2):
      return expr2str(e1) + "/" + expr2str(e2);
    case negation(AExpr e1):
      return "!" + expr2str(e1);
  }
}
//
//str getFirstQuestionName(list[AQuestion] questions){
//	if(isEmpty(questions)){
//		return "empty";
//	}
//	
//	return questions[
//}
 
str createEvalTree(list[AQuestion] qs) {

	str tree = "{";
	
	for(AQuestion q <- qs){
		switch(q) {
		    case qnormal(str _, str name, AType _):
		    	tree += "<name>: undefined,";
		    case qcomputed(str _, str name, AType _, AExpr expr):
		    	tree += "<name>: \"<expr2str(expr)>\",";
		    case qifthen(AExpr expr, list[AQuestion] questions):{
		    	tree += "_conditional_<arbInt(999999)>: {condition: \"<expr2str(expr)>\",";
		    	
		    	tree += "_if: ";
		    	tree += createEvalTree(questions);
		    	tree += ",_else: {}";
		    	
		    	tree += "},";
		    }
		    case qifthenelse(AExpr expr, list[AQuestion] questions, list[AQuestion] questions2):{
		    	tree += "_conditional_<arbInt(999999)>: {condition: \"<expr2str(expr)>\",";
		    	
		    	tree += "_if: ";
		    	tree += createEvalTree(questions);
		    	tree += ",_else: ";
		    	tree += createEvalTree(questions2);
		    	
		    	tree += "},";
		    } 
		  }
	}
  
 	return tree + "}"; 
}

value defaultJSValue(AType \type) {
  switch (\type) {
    case integer():
      return 0;
    case boolean():
      return false;
    case string():
      return "\"\"";
  }
}

str form2js(AForm f) {
	rel[str name, AType \type] names = {};

  	for(/AQuestion q := f.questions) {
  		if(q is qnormal || q is qcomputed)
  			names += {<q.name, q.\type>};
	}
	
	str vEnv = "var vEnv = {";
	for(<str name, AType \type> <- names) vEnv += "<name>: <defaultJSValue(\type)>,";
	vEnv += "};";
	
 	return vEnv + "var tree =" + createEvalTree(f.questions);
}
