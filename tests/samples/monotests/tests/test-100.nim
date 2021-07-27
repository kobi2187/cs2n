import dotnet/system
import dotnet/system/runtime/interopservices

type Object* = ref object
  v: int
  u_Raw: 


proc g_object_get(obj: int) =
  discard


method getProperty*(this: Object) =
  g_object_get(this.u_Raw)


proc main*(): int =
  return 0


method raw*(this: Object): int = this.u_Raw
method raw*(this: Object, value: int): int = this.u_Raw = value



