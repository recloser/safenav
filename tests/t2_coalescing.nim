import unittest, safenav, options

type
  Cons = ref object
    value: int
    next: Cons

let cons = Cons(value: 1, next: Cons(value: 2))

test "coalescing operator":
  check:
    (10 + (cons$.next$.value ?? 0) + 10) == 22
    (10 + (cons$.next$.next$.value ?? 0) + 10) == 20
    (10 + (cons$.next$.next$.value ?? cons$.next$.next$.value ?? 5) + 10) == 25
    (cons$.next ?? cons) == cons.next
    (cons$.next$.next$.next ?? cons) == cons