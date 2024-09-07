### Macros
##### @Json
```
public macro Json(input: Tokens): Tokens
```
在`@Json`中直接编写json
### Extends
##### public interface ToJsonValue
```
func toJsonValue(): JsonValue
```
提供转换成`JsonValue`的能力

##### extend Bool <: ToJsonValue
```
public func toJsonValue(): JsonBool
```
`bool`转成`JsonBool`

##### extend Float64 <: ToJsonValue
```
public func toJsonValue(): JsonFloat
```
`Float64`转成`JsonFloat`

##### extend Int64 <: ToJsonValue
```
public func toJsonValue(): JsonInt
```
`Int64`转成`JsonInt`

##### extend String <: ToJsonValue
```
public func toJsonValue(): JsonString
```
`String`转成`JsonString`

##### extend\<T> Array\<T> <: ToJsonValue where T <: ToJsonValue
```
public func toJsonValue(): JsonArray 
```
`Array<T>`转成`JsonArray`，数组元素转成对应的`JsonValue`


##### extend<T> ArrayList<T> <: ToJsonValue where T <: ToJsonValue
```
public func toJsonValue(): JsonArray
```
`ArrayList<T>`转成`JsonArray`，数组元素转成对应的`JsonValue`

##### extend<T> TreeMap<String, T> <: ToJsonValue where T <: ToJsonValue
```
public func toJsonValue(): JsonObject
```
`TreeMap<String, T>`转成`JsonObject`，`TreeMap`中的键值对，对应`JsonObject`中的键值对

##### extend<T> HashMap<String, T> <: ToJsonValue where T <: ToJsonValue
```
public func toJsonValue(): JsonObject
```
`HashMap<String, T>`转成`JsonObject`，`HashMap`中的键值对，对应`JsonObject`中的键值对

##### extend<T> Option<T> <: ToJsonValue where T <: ToJsonValue
```
public func toJsonValue(): JsonValue
```
`Option<T>`转成`JsonValue`，两种情况：
- `Option.Some`，将内部值转成对应的`JsonValue`
- `Option.None`，返回`JsonNull`

##### extend JsonValue <: ToJsonValue
```
public func toJsonValue(): JsonValue { this }
```
`toJsonValue()`仅仅用于返回自身下面的`JsonXX`同理
##### extend JsonBool 
```
public func ToJsonValue(): JsonBool { this }
```

##### extend JsonFloat 
```
public func ToJsonValue(): JsonFloat { this }
```

##### extend JsonInt 
```
public func ToJsonValue(): JsonInt { this }
```

##### extend JsonString 
```
public func ToJsonValue(): JsonString { this }
```

##### extend JsonNull 
```
public func ToJsonValue(): JsonNull { this }
```

##### extend JsonArray 
```
public func ToJsonValue(): JsonArray { this }
```

##### extend JsonObject 
```
public func ToJsonValue(): JsonObject { this }
```