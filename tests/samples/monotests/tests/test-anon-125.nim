import dotnet/system
import dotnet/system/collections/generic

type HS[T] = ref object

proc newHS(comparer: IEqualityComparer[T]): HS =
  new result

type Test = ref object

proc foo[T](c: IEqualityComparer[T]) =
  var a : Func[HS[T]] = ()=> return newHS[T](c)

proc main*(): int =
  foo[object](nil)
  return 0