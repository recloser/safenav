import macros, options
from sugar import dump

type Nilable[T] = ptr | ref | cstring | proc

proc ShouldFlatten() {.inline.} = discard

template getType(expr: untyped): untyped =
    type((block:
            let r = expr;
            r))

proc deepest(n: NimNode): NimNode =
  if n.len > 0 and n[0].kind in {nnkDotExpr, nnkBracketExpr, nnkCall}:
      deepest(n[0])
  else:
      n

proc impl(a, b: NimNode; ptrtype: bool): NimNode =
    #echo treeRepr a
    #echo treeRepr b

    var aOpt: NimNode = a
    if a.len > 0 and a[0].kind == nnkCall:
        if a[0][0] == bindsym"ShouldFlatten":
            aOpt = quote do: flatten(`a`)

    let aGet =
        if ptrtype: aOpt
        else: quote do: get(`aOpt`)

    proc fixup(x: var NimNode; recursed = false) =
      if x.kind == nnkIdent:
        x = quote do: `aGet`.`x`
      elif x.kind == nnkBracket:
        if  x.len > 0:
          x = nnkBracketExpr.newTree(aGet, x[0])
        else:
          x = quote do: `aGet`[]
      elif x.kind == nnkPar:
        let call = nnkCall.newTree(aGet)
        for arg in x:
          call.add arg
        x = call
      elif not recursed:
        var d = deepest(x)
        var d0 = d[0]
        fixup(d0, true)
        d[0] = d0
      else:
        x = quote do: `aGet`.`x`

    var b = b
    fixup(b)

    let checkExpr = if not ptrtype: quote do: `aOpt`.isNone
                    else: quote do: isNil(`aOpt`)

    #dump repr checkExpr
    #dump repr b

    result = quote do:
      when not compiles(`b` is Nilable):
        if not `checkExpr`:
          `b`
      else:
        when not (`b` is Nilable):
          ShouldFlatten()
        if `checkExpr`:
          when `b` is Nilable:
            nil
          else:
            none(getType(`b`))
        else:
          when `b` is Nilable:
            `b`
          else:
            some(`b`)

    #dump repr result
    #echo treeRepr result

macro `$.`*[T](a: Option[T]; b: untyped): untyped =
  result = impl(a, b, false)

macro `$.`*(a: Nilable; b: untyped): untyped =
  result = impl(a, b, true)

macro `??`*[T](a: Option[T], b: untyped): untyped =
  #dump treerepr a
  #dump treerepr b
  result = quote do:
    when `b` is Option:
      if isSome(`a`): `a`
      else: `b`
    else:
      if isSome(`a`): unsafeGet(`a`)
      else: `b`

macro `??`*[T: Nilable](a: T, b: untyped): untyped =
  result = quote do:
    if isNil(`a`): `b`
    else: `a`

when isMainModule:
  type
    Cons = ref object
      value: int
      next: Cons

  let cons = Cons(value: 1, next: Cons(value: 2))

  let q: int = (10 + (cons$.next$.next$.value ?? cons$.next$.next$.value ?? 5) + 10)

  var called = false
  var consNil: Cons
  proc sideEffect(q: int) =
    called = true

  expandMacros:
    consNil$.value.sideEffect

  # doAssert (10 + (cons$.next$.next$.value ?? cons$.next$.next$.value ?? 5) + 10) == 25