# Juson

使用 Juson 轻松生成 JSON，并支持嵌入 **变量**、**表达式** 和 **动态结构**。Juson 让编写 JSON 像使用本地语言语法一样自然，允许您将数组、集合甚至自定义类型无缝集成到 JSON 对象中，同时不妨碍**编译时检查**和**类型安全**。
主要特点包括：
- 内联变量和表达式： 直接在 JSON 结构中注入值、变量或表达式。
- 尾随逗号支持： 使用可选的尾随逗号，使 JSON 更加整洁，减少手动格式化的需要。

>目前自动序列化/反序列化宏`@Juson`正在开发中，请在feature/json-serializable分支上查看
>导入方式： juson = { git = "https://gitcode.com/Dacec/juson", branch = "feature/json-serializable", output-type = "static"}

### @Json
##### @Json中使用变量
变量的类型需要继承[`ToJsonValue`](./docs/api.md#public-interface-tojsonvalue)接口
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
表达式的类型需要继承[`ToJsonValue`](./docs/api.md#public-interface-tojsonvalue)接口
```
let ofStr = {i: String => "[${i}]"}
let name = "Elis"
let j = @Json(
    {
        "key1": 4 * 3, // 12
        "key2" |> ofStr: ofStr(name), // "[key2]": "[value2]"
        "key3" * 2: "value3" + "_plus", // "key3key3": "value3_plus"
    }
)
```

##### @Json中使用数组(`Array`/`ArryaList`)动态生成Json数组
数组元素需要继承[`ToJsonValue`](./docs/api.md#public-interface-tojsonvalue)接口
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
key类型必须是`String`，value需要继承[`ToJsonValue`](./docs/api.md#public-interface-tojsonvalue)
```
let map1 = HashMap<String, ToJsonValue>([("name", "aaa"), ("age", 23)])
let map2 = TreeMap<String, Int64>([("k1", 17), ("k2", 19)])
let j = @Json(
    {
        "key1": map1, // {"name": "aaa", "age": 23}
        "key2": map2  // {"k1": 17, "k2": 19}
    }
)
```

##### @Json中使用Option(Some/None)
`Option<T>`,T需要继承[`ToJsonValue`](./docs/api.md#public-interface-tojsonvalue)
```
let a = (1i64 as Int64)
let b = ("str" as Int64)
let j = @Json(
    {
        "key1": a, // 1
        "key2": b  // null
    }
)
```

##### @Json中嵌套使用JsonValue
这其实也是@Json中使用表达式的一部分，`JsonValue`也继承了[`ToJsonValue`](./docs/api.md#public-interface-tojsonvalue)
```
let a = @Json(4 * 8 + 2)
let b = @Json("jsonString")
let j = @Json(
    {
        "key1": a, // 34
        "key2": b,  // "jsonString"
        "key3": @Json({
            "innerKey": "innerValue"
        })
    }
)
```

##### @Json编写一般json
很多时候不需要上面的特性，一般的json就够用了
```
let j = @Json(
    {
        "name": "Jnnn",
        "age": 24,
        "isEmployed": true,
        "children": null,
        "address": {
            "city": "city1",
            "zipcode": 10001
        },
        "skills": ["Cangjie", "Rust", "Go"],
    }
)
```
### import
```cj
import juson.*
```
上面的`import`相当于导入如下内容
```cj
import std.collection.HashMap
import encoding.json.*
import juson.ext.ToJsonValue
import juson.*
```

### API
[API文档](./docs/api.md)

### 注意
- 外部定义的`null`变量无法在宏内使用，宏内`null`被识别为`JsonNull()`
- 宏内部的数组优先被识别为`JsonArray`，而不是`Array`字面量。要宏内创建Array实例，请使用`Array<T>([...])`
- 宏内作为key的变量/表达式类型必须是`String`，其他地方的变量/表达式必须继承[`ToJsonValue`](./docs/api.md#public-interface-tojsonvalue)接口
- 虽然可以编译运行，但是建议**不要**在@Json中嵌套@Json，会影响编译期宏展开速度

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

### 参考
https://github.com/Zxilly/json-cj
