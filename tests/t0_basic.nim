import unittest, safenav, options

type
  Cons = ref object
    value: int
    next: Cons

  Foo = object
    x: int
    y: Option[Cons]

proc square(n: int): int = n * n

let cons = Cons(value: 1, next: Cons(value: 2))

test "pointer types return pointers":
  check:
    (cons$.next) is Cons
    (cons$.next) != nil
    (cons$.next$.next) == nil

test "value types are wrapped in an Option":
  check:
    (cons$.value) is Option
    (cons$.value).get == 1
    (cons$.next$.value).get == 2
    (cons$.next$.next$.value).isNone

  let fooNone = Foo(x: 543, y: none(Cons))
  check:
    (fooNone.y$.value).isNone
    (fooNone.y$.next) == nil

test "index access":
  var s: ref seq[int]
  check (s$.[0]).isNone

  new(s)
  s[] = @[1, 2, 3]
  check (s$.[1]).get == 2

  var obj = (somefield: some((someseq: @[123])))
  check (obj.somefield$.someseq[0]).get == 123

  let cstr: cstring = "test"
  check (cstr$.[0]).get == 't'

  let cstrNil: cstring = nil
  check (cstrNil$.[0]).isNone

test "dereferencing":
  var s: ref string
  check (s$.[]).isNone
  check (s$.[] ?? "test") == "test"

  new(s)
  s[] = "abcd"
  check (s$.[]).isSome
  check (s$.[] ?? "test") == "abcd"
  check (s$.[][0]).get == 'a'

test "method calling":
  let opt = some(2)

  check get(opt$.square) == 4
  check (opt$.square.square).get == 16

  proc maybeSquare(n: int): Option[int] =
    if n mod 2 == 0: some(square(n))
    else: none(int)

  check (opt$.maybeSquare$.square).get == 16
  check (opt$.square.maybeSquare).get.get == 16

  let optOdd = some(3)
  check (optOdd$.maybeSquare$.square).isNone
  let o: Option[Option[int]] = optOdd$.square.maybeSquare
  check o.isSome
  check o.get.isNone

test "void method calling":
  var called = false
  var consNil: Cons
  proc sideEffect(q: int) =
    called = true

  cons$.next$.next$.next$.value.sideEffect
  check called == false
  cons$.value.sideEffect
  check called == true

test "proc calling":
  proc identity[T](t: T): T =
    result = t

  let a = identity cons$.next
  check a != nil
  let b = identity cons$.next$.next$.next.value ?? 123
  check b == 123
  let c = identity cons$.next$.next$.next.value ?? cons$.next$.next$.next$.next.value ?? 234
  check c == 234
  let d = identity cons$.next$.next$.value ?? cons$.next$.value ?? 234
  check d == 2
  let e = identity cons$.next$.next$.next.value ?? 123 + 1
  check e == 124
  let f = identity 1 + (cons$.next$.next$.next.value ?? 10) + 1
  check f == 12

test "various tests":
  let fooSome = Foo(x: 543, y: some(cons))
  check (fooSome.y$.value) is Option
  check (fooSome.y$.next) is Cons
  check (fooSome.y$.next$.value) is Option
  check (fooSome.y$.next$.next$.next) == nil
  check get(fooSome.y$.value) == 1

  let obj = (somefield: some((someseq: @[5])))
  check (obj.somefield$.someseq[0].square).get == 25