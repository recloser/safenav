# safenav
[Safe navigation operators](https://en.wikipedia.org/wiki/Safe_navigation_operator) for Nim

This experimental package provides two operator macros, a safe navigation operator (``$.``) and a null coalescing operator (``??``).
The operators work both on pointer types and the ``Option`` type from the standard ``options`` package.
The ``$.`` operator lets you avoid writing verbose if checks when interacting with objects which are wrapped in an Option or nilable.

```nim
import safenav, options

type Node = ref object
  value: int
  next: Node

let cons = Node(value: 1, next: Node(value: 2))

# $. will wrap value types in an Option
let x: Option[int] = cons$.next$.value
doAssert x.get == 2
doAssert (cons$.next$.next$.value).isNone

# pointer types aren't wrapped
let y: Node = cons$.next$.next$.next
doAssert y == nil

# procs can be safely called
cons$.next$.value.echo # prints 2
cons$.next$.next$.value.echo # doesn't print

# proc fields/vars can also be safely called
var someProc = proc(a, b: int): int = a + b
doAssert (someProc$.(2, 2)).get == 4
someProc = nil
doAssert (someProc$.(2, 2)).isNone

# sequences can be safely indexed
var z: cstring = "abcd"
doAssert (z$.[1]).get == 'b'
z = nil
doAssert (z$.[1]).isNone
```

The ``??`` operator lets you specify a default value for a nilable/Optional expression.
```nim
var n = cons$.next$.next$.value ?? 123
doAssert n == 123

# it can also be chained
n = cons$.next$.next$.value ?? cons$.next.value ?? 321
doAssert n == 2

doAssert (cons$.next$.next ?? cons) == cons
```
