//input:{name, value}
function evalTree(treeLevel, input) {
  if (!treeLevel) {
    return;
  }

  Object.keys(treeLevel).forEach(function (qName) {
    if (treeLevel[qName] === undefined) { //qnormal
      if (input && input.name === qName)
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

// evaluate and expression
function evalExpr(expr) {
  eval("with (vEnv) {var result = (" + expr + ")}");
  if (result === "true") {
    result = true;
  } else if (result === "false") {
    result = false;
  }
  return result;
}

// check if the old and new value envs are different
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
  solve()
  $("form").change(function (e) {
    solve(e.target);
  });
});
