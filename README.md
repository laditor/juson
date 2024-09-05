# json4cj

用Json宏生成JsonValue
- 在Json中使用**变量**和**表达式**
- 尾随逗号支持

### @Json
在宏中直接写Json，并且可以使用变量和表达式
```
let str = "string"
let j = @Json(
    {
    "array": [1, "string", true, null, {"key": "value"}],
    "array1": [1, 2, str],
    }
)
```

### import
```cj
import json4cj.*
```
上面的`import`相当于导入如下内容
```cj
import std.collection.HashMap
import encoding.json.*
import json4cj.*
import json4cj.ext.ToJsonValue
```

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

### 导入项目
将下面内容放在`cjpm.toml`的`[dependencies]`下<br>选**一种**你喜欢的就行
```
[dependencies.json4cj]
  git = "https://gitcode.com/Dacec/json4cj"
  branch = "main"
  output-type = "static"
```
```
json4cj = { git = "https://gitcode.com/Dacec/json4cj", branch = "main", output-type = "static"}
```

### 案例
```cj
import json4cj.*

main(): Int64 {
    let key1 = "key"
    let ofStr = {s: String => "[${s}]"}
    let numStr = "1, 2, 5, 12, 9, 4, 3.5"
    let info = HashMap<String, ToJsonValue>([
        ("name", "Fiona"),
        ("age", 40)
    ])
    
    let a = @Json(
        {
            "calculation": 1.0 + 2.0,  // 简单的数学表达式
            "repeated": "bbb" * 3,  // 字符串操作
            ofStr("ccc"): ofStr("ccc"),  // 函数表达式调用
            "key_transformed": numStr.split(",") |>
                map {i => i.trimAscii() + "g"} |> collectArray,  // 动态数组生成
            key1: "Dynamic key with a value",
            "null_value": null,  // null 值
            "infos": [info],  // 使用map动态生成对象
        }
    )

    println(a.toJsonString())
    return 0
}
```