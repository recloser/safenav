import unittest, safenav, options

proc square(n: int): int = n * n
proc add2(a, b: int): int = a + b

test "nilable proc calling":
  var nilableProc = square
  check (nilableProc$.(5)).get == 25
  check (nilableProc$.(5).square).get == 625
  check (nilableProc$.(5).add2(10).add2(10)).get == 45
  nilableProc = nil
  check (nilableProc$.(5)).isNone

  var twoArgProc = add2
  check (twoArgProc$.(1, 2)).get == 3
  check compiles(twoArgProc$.((1, 2))) == false

  var obj1 = (a: some((someproc: square)))
  check (obj1.a$.someproc(5)).get == 25

  var obj2 = (a: (someproc: square))
  check (obj2.a.someproc$.(5)).get == 25
  #check compiles(obj2.a.someproc$.((5))) == false
  check (obj2.a.someproc$.(5).square).get == 625

  obj2.a.someproc = nil
  check (obj2.a.someproc$.(5)).isNone
  check (obj2.a.someproc$.(5).square).isNone