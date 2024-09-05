# json4cj

用Json宏生成JsonObject
- 在Json中使用**变量**和**表达式**
- 尾随逗号支持

### 导入项目
将下面内容放在`cjpm.toml`的`[dependencies]`下
```
[dependencies.json4cj]
  git = "https://gitcode.com/Dacec/json4cj"
  branch = "main"
  output-type = "static"
```
### 案例
```
import json4cj.*

main(): Int64 {
    let name = "kiiiia"
    let age = 16
    let key1 = "key"
    let illegal = "illegal"
    let a = @Json(
        {
            "aaa": "aaa",
            "bbb" + "bbb": "bbb" + "bbb",
            key1 + "123": "value1",
            illegal: null,
            "infos": [
                {
                    "name": name,
                    "age": age,
                }
            ],
        }
    )
    println(a.toJsonString())
    0
}
```