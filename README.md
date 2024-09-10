# juson

### @Juson
用`@Juson`自动序列化/反序列化`class`/`struct`

### @Json
用Json宏生成JsonValue
- 在Json中使用**变量**和**表达式**
- 尾随逗号支持

### import
```cj
import juson.*
```
上面的`import`相当于导入如下内容
```cj
import std.collection.HashMap
import encoding.json.{JsonValue, JsonBool, JsonInt, JsonFloat, JsonString, JsonArray, JsonObject, JsonNull}
import juson.core.{JusonSerializable, JusonDeserializable}
```
### 导入项目
将下面内容放在`cjpm.toml`的`[dependencies]`下<br>选**一种**你喜欢的就行
```
[dependencies.juson]
  git = "https://gitcode.com/Dacec/juson"
  branch = "feature/json-serializable"
  output-type = "static"
```
```
juson = { git = "https://gitcode.com/Dacec/juson", branch = "feature/json-serializable", output-type = "static"}
```

### @Juson案例
```cj
import juson.*

@Juson
class Address {
    @Field[skip=deserializing]
    var street: String = ""

    var city: String = ""
}
 
@Juson 
struct User {
    @Field[name="username", default="unknown"]
    var name: String = "" 

    @Field[required=true]
    var age: Int64 = 0

    @Field[skip=serializing]
    var email: String = ""

    @Field[name="住址"]
    var address: Address = Address()
}
 

main(): Int64 {
    var user1 = User()
    user1.name = "Joana"
    user1.age = 23
    user1.email = "joana@xxx.com"
    user1.address.street = "456 Elm St"
    user1.address.city = "San Francisco"
    println(user1.jusonSerialize().toJsonString())

    let j = @Json({
        // "username": "Joana",
        "age": 23,
        "email": "joana@xxx.com",
        "住址": {
            "street": "456 Elm St",
            "city": "San Francisco", 
        },
    })
    let user2 = User.jusonDeserialize(j)
    println("User2.name: ${user2.name}")
    println("User2.age: ${user2.age}")
    println("User2.email: ${user2.email}")
    println("User2.address.street: ${user2.address.street}")
    println("User2.address.city: ${user2.address.city}")
    0
}
```
### @Json案例
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
