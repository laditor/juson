# juson

用Json宏生成JsonValue
- 在Json中使用**变量**和**表达式**
- 尾随逗号支持

### @Json
##### @Json中使用变量
变量的类型需要继承`ToJsonValue`接口
```
let str = "string"
let j = @Json(
    {
        "array": [1, "string", true, null, {"key": "value"}],
        "array1": [1, 2, str], // [1, 2, "string"]
    }
)
```

##### @Json中使用表达式
表达式的类型需要继承`ToJsonValue`接口
```
let ofStr = {i: String => "[${i}]"}
let name = "Elis"
let j = @Json(
    {
        "key1": 4 * 3, // 12
        "key2" |> ofStr: ofStr("value2"), // "[key2]": "[value2]"
        "key3" * 2: "value3" + "_plus", // "key3key3": "value3_plus"
    }
)
```

##### @Json中使用数组(`Array`/`ArryaList`)动态生成Json数组
数组元素需要继承`ToJsonValue`接口
```
let arr1 = [1, 2, 3, 4, 5]
let arr2 = ArrayList(["a", "b", "c"])
let j = @Json(
    {
        "key1": arr1, // [1, 2, 3, 4, 5]
        "key2": arr2  // ["a", "b", "c"]
    }
)
```

##### @Json中`HashMap`/`TreeMap`动态生成Json对象
key类型必须是`String`，value需要继承`ToJsonValue`
```
let map1 = HashMap<String, ToJsonValue([("name", "aaa"), ("age", 23)])
let map2 = TreeMap<String, Int64>([("k1": 17), ("k2", 19)])
let j = @Json(
    {
        "key1": map1, // {"name": "aaa", "age": 23}
        "key2": map2  // {"k1": 17, "k2": 19}
    }
)
```

##### @Json中使用Option(Some/None)
`Option<T>`,T需要继承`ToJsonValue`
```
let a = (1i64 as Int64)
let b = (1i64 as Int8)
let j = @Json(
    {
        "key1": a, // 1
        "key2": b  // null
    }
)
```

### 注意
- 外部定义的`null`变量无法在宏内使用，宏内`null`被识别为`JsonNull()`
- 宏内部的数组优先被识别为`JsonArray`，而不是`Array`字面量。要宏内创建Array实例，请使用`Array<T>([...])`
- 宏内作为key的变量/表达式类型必须是`String`，其他地方的变量/表达式必须继承`ToJsonValue`接口

### import
```cj
import juson.*
```
上面的`import`相当于导入如下内容
```cj
import std.collection.HashMap
import encoding.json.*
import juson.*
import juson.ext.ToJsonValue
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
[dependencies.juson]
  git = "https://gitcode.com/Dacec/juson"
  branch = "main"
  output-type = "static"
```
```
juson = { git = "https://gitcode.com/Dacec/juson", branch = "main", output-type = "static"}
```

### 案例
```cj
import std.collection.{map, collectArray}
import juson.*

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