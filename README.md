# Juson

Juson 是一个高效且灵活的 JSON 序列化和反序列化库，旨在简化与 JSON 数据的交互。通过自动生成序列化和反序列化的方法，Juson 提供了便捷的 API，使得开发者能够快速地将对象转换为 JSON 以及将 JSON 转换为对象。

## 功能特点

### 自动生成序列化/反序列化方法

使用 `@Juson`宏，可以自动为类和结构体生成 `jusonSerialize` 和 `jusonDeserialize` 方法，极大地减少了手动编写代码的工作量。

```cj
@Juson
class Person {
    @Field[name="name"]
    var name: String
    @Field[default=0]
    var age: Int
}
```

### 属性灵活配置

`@Field` 宏允许开发者为字段配置不同的属性，如指定 JSON 中的键名、默认值以及字段的跳过行为（如序列化时跳过、反序列化时跳过等），提供了灵活的使用场景。

```cj
@Field[name="user_age", default=18, skip=serializing]
var age: Int
```

### 灵活的 JSON 表达式支持

使用 `@Json` 宏，开发者可以在代码中直接编写 JSON 表达式，并将其转换为 `JsonValue`。支持嵌入变量和表达式，多种数据类型，包括字符串、数值、数组(`Array`/`ArrayList`)和字典(`TreeMap`/`HashMap`)等都可以转换为 `JsonValue`。

```cj
let json = @Json({
    "name": "Alice",
    "age": 30,
    "skills": ["programming", "design"]
})
```

### 接口扩展支持

Juson 通过 `JusonSerializable` 和 `JusonDeserializable` 接口支持对象的序列化和反序列化。开发者可以通过扩展这些接口，轻松为自定义类型添加序列化和反序列化能力。

```cj
extend MyType <: JusonSerializable {
    public func jusonSerialize(): JsonValue {
        // 自定义序列化逻辑
    }
}
```

### 内置类型支持

Juson 内置对[多种类型](./docs/api.md#extend-jusonserializable)的支持，包括整数、浮点数、布尔值、字符串等，确保开发者可以轻松地将这些类型与 JSON 进行交互。

### Option 类型处理
Juson 利用 `Option` 类型处理空值。`None`对应 JSON 中的 `null`，`Some`对应 JSON 中的非 `null` 值。

在序列化时，`Some`值会序列化为对应类型的 JSON 值，`None`值则序列化为 `null`。

在反序列化时，`null`值会转换为 `None`，非 `null`值会转换为 `Some`。

## 使用示例

以下是一个简单的使用示例，展示如何定义一个类并通过 Juson 库进行序列化和反序列化：

```cj
import juson.*

@Juson
class User { // 也可以定义一个struct
    @Field[name="username"]
    let name: String
    @Field[default=0]
    let age: Int
}

main(): Int64 {
    let user = User(name: "Alice", age: 20)
    println(user.jusonSerialize().toJsonString()) // 序列化为JsonValue并输出为JSON字符串

    let json = @Json({
        "username": "Bob",
        "age": 30,
    })
    let user2 = User.jusonDeserialize(json) // 反序列化为User对象
    println(user2.name)
    println(user2.age)
    return 0
}
```
更多示例请参考[示例文档](./docs/samples.md)。

## API文档

请参考[API文档](./docs/api.md)。

## 安装
将下面内容放在`cjpm.toml`的`[dependencies]`下
选**一种**你喜欢的就行
```
[dependencies.juson]
  git = "https://gitcode.com/Dacec/juson"
  branch = "main"
  output-type = "static"
```
```
juson = { git = "https://gitcode.com/Dacec/juson", branch = "main", output-type = "static"}
```
