// var tree = {
//   kek: undefined,
//   kek2: "kek + 12",
//   hasBoughtHouse: undefined,
//   hasMaintLoan: undefined,
//   hasSoldHouse: undefined,

//   _conditional_1: { // DON'T FORGET TO ITERATE NUMBERS
//     condition: "hasSoldHouse",
//     _if: {
//       sellingPrice: undefined,
//       privateDebt: undefined,
//       valueResidue: "kek - privateDebt"
//     },
//     _else: {}
//   }
// }

//  var vEnv = { kek: 0, kek2: 0, hasBoughtHouse: false, hasMaintLoan: false, hasSoldHouse: false, sellingPrice: 0, privateDebt: 0, valueResidue: 0 };

//input:{name, value}
function evalTree(treeLevel, input) {
  if (!treeLevel) {
    return;
  }

  Object.keys(treeLevel).forEach(function (qName) {
    if (treeLevel[qName] === undefined) { //qnormal
      if (input.name === qName)
        vEnv[qName] = evalExpr(input.value);
    } else if (treeLevel[qName] instanceof Object) { //conditional
      if (evalExpr(treeLevel[qName].condition)) {
        evalTree(treeLevel[qName]["_if"], input);
      } else {
        evalTree(treeLevel[qName]["_else"], input);
      }
    } else { //qcomputed
      vEnv[qName] = evalExpr(treeLevel[qName]);
    }
  });
}

function evalExpr(expr) {
  eval("with (vEnv) {var result = (" + expr + ")}");
  if (result === "true") {
    result = true;
  } else if (result === "false") {
    result = false;
  }
  return result;
}

function isDifferent(old, vEnv) {
  var different = false;
  Object.keys(old).forEach(function (key) {
    if (old[key] != vEnv[key])
      different = true;
  });
  return different;
}

// solve until nothing changes
function solve(input) {
  var oldVEnv;

  do {
    oldVEnv = JSON.parse(JSON.stringify(vEnv));
    evalTree(tree, input);
  } while (isDifferent(oldVEnv, vEnv));
  update();
}

// Update all the values from visible input boxes
function fetchValues(){
  $("input").each(function(e, i){
    if($(this).is(":visible") && i.type == "number"){
      vEnv[i.name] = $(i).val();
    }
  });
}

// update the DOM
function update() {
  // show-hide if-else stuff
  $(".toggled").each(function (e, i) {
    if (evalExpr(i.getAttribute("about"))) {
      $(i).show();
    } else {
      $(i).hide();
    }
    fetchValues();
  });

  // display computed questions
  $('[readonly="readonly"]').each(function (e, i) {
    $(i).val(vEnv[i.name]);
  });
}

$(document).ready(function () {
  update()
  $("form").change(function (e) {
    solve(e.target);
  });
});