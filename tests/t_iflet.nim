import unittest, options
from safenav import ifLet

test "basic ifLet":
  var x = 0
  block:
    ifLet whatever := 543:
      x = whatever
    check x == 543

    ifLet whatever := some(123):
      x = whatever
    check x == 123

    ifLet whatever := none(int):
      x = whatever
    check x == 123

  block:
    ifLet:
      a = 1
      b = 2
      c = 3
    do:
      x = a + b + c
    check x == 6

  block:
    ifLet:
      a = 123
      b = 321
      c = none(int)
    do:
      x = a + b + c
    else:
      x = -1
    check x == -1

  block:
    var count = 0
    proc counter(): int =
      count += 1
      count

    ifLet:
      a = counter()
      b = none(int)
      c = counter()
    do:
      x = a + b + c
    else:
      x = 987
    check x == 987
    check count == 1