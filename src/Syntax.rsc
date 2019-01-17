module Syntax

extend lang::std::Layout;
extend lang::std::Id;

import Resolve;
import IO;

/*
 * Concrete syntax of QL
 */

start syntax Form = "form" Id "{" Question* "}"; 

// TODO: question, computed question, block, if-then-else, if-then 
syntax Question
	= normal: Str Id":" Type
	| computed: Str Id":" Type "=" Expr 
	| ifthen: "if" "("Expr")" "{" Question* "}"
	| ifthenelse: "if" "("Expr")" "{" Question* "}" "else" "{" Question* "}" ; 

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)

syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | boolean: Bool
  | number: Int
  | string: Str
  > brackets: "(" Expr ")"
  > negation: "!" Expr
  > left (
    left div: Expr l "/" Expr r
  | left mul: Expr l "*" Expr r
  )
  > left (
    left minus: Expr l "-" Expr r
  | left plus: Expr l "+" Expr r
  )
  > left (
    smallerequal: Expr l "\<=" Expr r
  | largerequal: Expr l "\>=" Expr r 
  | smaller: Expr l "\<" Expr r
  | larger: Expr l "\>" Expr r
  )
  > left (
    left notequal: Expr l "!=" Expr r
  | left equal: Expr l "==" Expr r
  )
  > left and: Expr l "&&" Expr r
  > left or: Expr l "||" Expr r
;
 
syntax Type 
  = string: "string"
  | integer: "integer"
  | boolean: "boolean";  
  
lexical Str = "\"" ![\"]* "\"";

lexical Int = [1-9][0-9]*;

lexical Bool = "true" | "false";

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
*/
 
start[Form] rename(start[Form] f, loc useOrDef, str name, UseDef useDef) {
  set[loc] usesDefs = {use | <loc use, loc def> <- useDef, def == useOrDef} + {def | <loc use, loc def> <- useDef, use == useOrDef};
 
  return visit(f) {
    case Id x => [Id]name when (x@\loc) in usesDefs
  }
}



