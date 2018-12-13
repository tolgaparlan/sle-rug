module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

// the reference graph
alias UseDef = rel[loc use, loc def];

UseDef resolve(AForm f) = uses(f) o defs(f);

// go through all references in the form 
Use uses(AForm f) {
  Use u = {};
  for (/r:ref(str x) := f){
    u += { <r.src, x> };
  }
  return u; 
}

Def defs(AForm f) {
  Def d = {};
  for (/AQuestion q := f, q has name){
    d += { <q.name, q.nref> };
  }
  return d; 
}