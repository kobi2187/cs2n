# import dotnet/system
# import dotnet/system/collections/generic
import sugar
type IEqualityComparer*[T] = ref object
type Func[T] = proc():T

type HS[T] = ref object
proc newHS[T](comparer: IEqualityComparer[T]): HS[T] =
  new result

type Test = ref object

proc foo[T](c: IEqualityComparer[T]) =
  var a : Func[HS[T]]
  a = () => newHS[T](c)
  # a = proc() : HS[T] = newHS[T](c)

proc main*(): int =
  foo[int](nil)
  return 0