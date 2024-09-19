# Macros
### @Juson
```cj
public macro Juson(input: Tokens): Tokens
```
修饰`class`或`struct`，为其自动生成`jusonSerialize`方法和`jusonDeserialize`方法，提供序列化和反序列化的能力。

### @Field
```cj
public macro Field(attrs: Tokens, input: Tokens): Tokens
```
在`@Juson`内部使用，修饰变量声明，为其添加属性，支持以下属性：
- `name`：指定json中的key，默认使用变量名。
```cj
@Field[name="my_key"]
var myVar: Int64
```
- `default`: 指定默认值，如果json中没有该key，则使用默认值
```cj
@Field[default=10]
var myVar: Int64
```
- `format`: 指定格式化字符串，用于格式化日期时间，针对`DateTime`类型。
```cj
@Field[format="yyyy-MM-dd"]
var myDate: DateTime
```
- `serialize`: 自定义序列化逻辑，后接函数，函数类型为`(T) -> JsonValue`，`T`是字段类型，返回序列化后的`JsonValue`。
> 与`format`一起使用时，函数类型为`(T, String) -> JsonValue`，`String`是`format`属性的值。
```cj
@Field[serialize=mySerializeFunc1]
var myVar: Int64

func mySerializeFunc1(value: Int64): JsonValue {
    return JsonInt(value)
}

@Field[format="yyyy-MM-dd", serialize=mySerializeFunc2]
var myDate: DateTime

func mySerializeFunc2(value: DateTime, format: String): JsonValue {
    return JsonString(value.toString(format))
}
```
- `deserialize`: 自定义反序列化逻辑，后接函数，函数类型为`(JsonValue) -> T`，`T`是字段类型，返回反序列化后的`T`。
> 与`format`一起使用时，函数类型为`(JsonValue, String) -> T`，`String`是`format`属性的值。
```cj
@Field[deserialize=myDeserializeFunc]
var myVar: Int64

func myDeserializeFunc(value: JsonValue): Int64 {
    return value.asInt().getValue()
}

@Field[format="yyyy-MM-dd", deserialize=myDeserializeFunc2]
var myDate: DateTime

func myDeserializeFunc2(value: JsonValue, format: String): DateTime {    
    return DateTime.parse(value.asString().getValue(), format)
}
```
- `skip`: 控制字段的跳过行为，默认不跳过
  - `skip=none`: 强制不跳过
  - `skip=serializing`: 序列化时跳过
  - `skip=deserializing`: 反序列化时跳过
  - `skip=all`: 序列化和反序列化都跳过
- 条件`skip`: 控制字段何时跳过
  - `skip=serializing{i => ...}`: `skip=serializing`后接`lambda`表达式，表达式类型是`(T) -> Bool`，`T`是字段类型，返回true时<u>序列化</u>跳过该字段。
  - `skip=deserializing{i => ...}`: `skip=deserializing`后接`lambda`表达式，表达式类型是`(JsonValue) -> Bool`，`T`是字段类型，返回true时<u>反序列化</u>跳过该字段。

```cj
@Field[skip=serializing]
var myVar1: Int64

@Field[skip=deserializing]
var myVar2: Int64

@Field[skip=all]
var myVar3: Int64

@Field[skip=serializing{i => i == ""}]
var myVar4: String

@Field[skip=deserializing{i => i.asInt().getValue() ==0}]
var myVar5: Int64

@Field[skip=serializing{_ => false}] // 不跳过
var myVar6: Int64
```

### @Json
```
public macro Json(input: Tokens): Tokens
```
在`@Json`中直接编写json, 并将其转成`JsonValue`。json的编写很自由，支持字符串、数值、数组、对象、变量、函数调用、动态数组生成(`Array`/`ArrayList`)、动态对象生成(`TreeMap`/`HashMap`)等。
- 作为`key`的表达式/变量必须是`String`类型。
- 作为`value`的表达式/变量可以必须继承`JusonSerializable`接口。
- `@Json`内的null值会被转成`JsonNull`，外部定义的`null`变量无法使用。
- `@Json`内的`[...]`优先被识别为Json数组，而不是`Array`字面量，可以使用`Array([...])`代替。
```cj
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
```

# Interfaces & Extensions
***
### public interface JusonSerializable
```
func jusonSerialize(): JsonValue
```
提供将对象转换成 `JsonValue` 的能力。

### Extend JusonSerializable
#### extend JsonValue <: JusonSerializable
```
public func jusonSerialize(): JsonValue { this }
```
返回 `JsonValue` 自身。

#### extend BigInt <: JusonSerializable
```
public func jusonSerialize(): JsonString
```
将 `BigInt` 转换成 `JsonString`。

#### extend DateTime <: JusonSerializable
```
public func jusonSerialize(): JsonString
public func jusonSerialize(format: String): JsonString
```
将 `DateTime` 转换成 `JsonString`，支持自定义格式化。

#### extend Decimal <: JusonSerializable
```
public func jusonSerialize(): JsonString
```
将 `Decimal` 转换成 `JsonString`。

#### extend Bool <: JusonSerializable
```
public func jusonSerialize(): JsonBool
```
将 `Bool` 转换成 `JsonBool`。

#### extend Int8 <: JusonSerializable
```
public func jusonSerialize(): JsonInt
```
将 `Int8` 转换成 `JsonInt`。

#### extend Int16 <: JusonSerializable
```
public func jusonSerialize(): JsonInt
```
将 `Int16` 转换成 `JsonInt`。

#### extend Int32 <: JusonSerializable
```
public func jusonSerialize(): JsonInt
```
将 `Int32` 转换成 `JsonInt`。

#### extend Int64 <: JusonSerializable
```
public func jusonSerialize(): JsonInt
```
将 `Int64` 转换成 `JsonInt`。

#### extend IntNative <: JusonSerializable
```
public func jusonSerialize(): JsonInt
```
将 `IntNative` 转换成 `JsonInt`。

#### extend UInt8 <: JusonSerializable
```
public func jusonSerialize(): JsonInt
```
将 `UInt8` 转换成 `JsonInt`。

#### extend UInt16 <: JusonSerializable
```
public func jusonSerialize(): JsonInt
```
将 `UInt16` 转换成 `JsonInt`。

#### extend UInt32 <: JusonSerializable
```
public func jusonSerialize(): JsonInt
```
将 `UInt32` 转换成 `JsonInt`。

#### extend UInt64 <: JusonSerializable
```
public func jusonSerialize(): JsonInt
```
将 `UInt64` 转换成 `JsonInt`。

#### extend UIntNative <: JusonSerializable
```
public func jusonSerialize(): JsonInt
```
将 `UIntNative` 转换成 `JsonInt`。

#### extend Float16 <: JusonSerializable
```
public func jusonSerialize(): JsonFloat
```
将 `Float16` 转换成 `JsonFloat`。

#### extend Float32 <: JusonSerializable
```
public func jusonSerialize(): JsonFloat
```
将 `Float32` 转换成 `JsonFloat`。

#### extend Float64 <: JusonSerializable
```
public func jusonSerialize(): JsonFloat
```
将 `Float64` 转换成 `JsonFloat`。

#### extend String <: JusonSerializable
```
public func jusonSerialize(): JsonString
```
将 `String` 转换成 `JsonString`。

#### extend<T> Array<T> <: JusonSerializable where T <: JusonSerializable
```
public func jusonSerialize(): JsonArray
```
将 `Array<T>` 转换成 `JsonArray`，其中每个元素都将调用 `jusonSerialize`。

#### extend<T> ArrayList<T> <: JusonSerializable where T <: JusonSerializable
```
public func jusonSerialize(): JsonArray
```
将 `ArrayList<T>` 转换成 `JsonArray`，其中每个元素都将调用 `jusonSerialize`。

#### extend<T> HashMap<String, T> <: JusonSerializable where T <: JusonSerializable
```
public func jusonSerialize(): JsonObject
```
将 `HashMap<String, T>` 转换成 `JsonObject`，其中每个键值对的值都将调用 `jusonSerialize`。

#### extend<T> TreeMap<String, T> <: JusonSerializable where T <: JusonSerializable
```
public func jusonSerialize(): JsonObject
```
将 `TreeMap<String, T>` 转换成 `JsonObject`，其中每个键值对的值都将调用 `jusonSerialize`。


#### extend<T> Option<T> <: JusonSerializable where T <: JusonSerializable
```
public func jusonSerialize(): JsonValue
```
将 `Option<T>` 转换成 `JsonValue`，如果为 `Some`，则调用 `jusonSerialize`；如果为 `None`，则返回 `JsonNull()`。

***

### public interface JusonDeserializable
```
func jusonDeserialize(jsonValue: JsonValue): T
```
提供将 `JsonValue` 转换成对象的能力。

### Extend JusonDeserializable
#### extend JsonValue <: JusonDeserializable<JsonValue>
```
public static func jusonDeserialize(jsonValue: JsonValue): JsonValue
```
返回`JsonValue`自身。

#### extend BigInt <: JusonDeserializable<BigInt>
```
public static func jusonDeserialize(jsonValue: JsonValue): BigInt
```
将 `JsonString` 转换成 `BigInt`。

#### extend DateTime <: JusonDeserializable<DateTime>
```
public static func jusonDeserialize(jsonValue: JsonValue): DateTime
public static func jusonDeserialize(jsonValue: JsonValue, format: String): DateTime
```
将 `JsonString` 转换成 `DateTime`，支持自定义格式化。

#### extend Decimal <: JusonDeserializable<Decimal>
```
public static func jusonDeserialize(jsonValue: JsonValue): Decimal
```
将 `JsonStrnig` 转换成 `Decimal`。

#### extend Bool <: JusonDeserializable<Bool>
```
public static func jusonDeserialize(jsonValue: JsonValue): Bool
```
将 `JsonBool` 转换成 `Bool`。

#### extend Int8 <: JusonDeserializable<Int8>
```
public static func jusonDeserialize(jsonValue: JsonValue): Int8
```
将 `JsonInt` 转换成 `Int8`。

#### extend Int16 <: JusonDeserializable<Int16>
```
public static func jusonDeserialize(jsonValue: JsonValue): Int16
```
将 `JsonInt` 转换成 `Int16`。

#### extend Int32 <: JusonDeserializable<Int32>
```
public static func jusonDeserialize(jsonValue: JsonValue): Int32
```
将 `JsonInt` 转换成 `Int32`。

#### extend Int64 <: JusonDeserializable<Int64>
```
public static func jusonDeserialize(jsonValue: JsonValue): Int64
```
将 `JsonInt` 转换成 `Int64`。

#### extend IntNative <: JusonDeserializable<IntNative>
```
public static func jusonDeserialize(jsonValue: JsonValue): IntNative
```
将 `JsonInt` 转换成 `IntNative`。

#### extend UInt8 <: JusonDeserializable<UInt8>
```
public static func jusonDeserialize(jsonValue: JsonValue): UInt8
```
将 `JsonInt` 转换成 `UInt8`。

#### extend UInt16 <: JusonDeserializable<UInt16>
```
public static func jusonDeserialize(jsonValue: JsonValue): UInt16
```
将 `JsonInt` 转换成 `UInt16`。

#### extend UInt32 <: JusonDeserializable<UInt32>
```
public static func jusonDeserialize(jsonValue: JsonValue): UInt32
```
将 `JsonInt` 转换成 `UInt32`。

#### extend UInt64 <: JusonDeserializable<UInt64>
```
public static func jusonDeserialize(jsonValue: JsonValue): UInt64
```
将 `JsonInt` 转换成 `UInt64`。

#### extend UIntNative <: JusonDeserializable<UIntNative>
```
public static func jusonDeserialize(jsonValue: JsonValue): UIntNative
```
将 `JsonInt` 转换成 `UIntNative`。

#### extend Float16 <: JusonDeserializable<Float16>
```
public static func jusonDeserialize(jsonValue: JsonValue): Float16
```
将 `JsonFloat` 转换成 `Float16`。

#### extend Float32 <: JusonDeserializable<Float32>
```
public static func jusonDeserialize(jsonValue: JsonValue): Float32
```
将 `JsonFloat` 转换成 `Float32`。

#### extend Float64 <: JusonDeserializable<Float64>
```
public static func jusonDeserialize(jsonValue: JsonValue): Float64
```
将 `JsonFloat` 转换成 `Float64`。

#### extend String <: JusonDeserializable<String>
```
public static func jusonDeserialize(jsonValue: JsonValue): String
```
将 `JsonFloat` 转换成 `String`。

#### extend<T> Array<T> <: JusonDeserializable<Array<T>> where T <: JusonDeserializable<T>
```
public static func jusonDeserialize(jsonValue: JsonValue): Array<T>
```
将 `JsonArray` 转换成 `Array<T>`。

#### extend<T> ArrayList<T> <: JusonDeserializable<ArrayList<T>> where T <: JusonDeserializable<T>
```
public static func jusonDeserialize(jsonValue: JsonValue): ArrayList<T>
```
将 `JsonArray` 转换成 `ArrayList<T>`。

#### extend<T> HashMap<String, T> <: JusonDeserializable<HashMap<String, T>> where T <: JusonDeserializable<T>
```
public static func jusonDeserialize(jsonValue: JsonValue): HashMap<String, T>
```
将 `JsonObject` 转换成 `HashMap<String, T>`。

#### extend<T> TreeMap<String, T> <: JusonDeserializable<TreeMap<String, T>> where T <: JusonDeserializable<T>
```
public static func jusonDeserialize(jsonValue: JsonValue): TreeMap<String, T>
```
将 `JsonObject` 转换成 `TreeMap<String, T>`。

#### extend<T> Option<T> <: JusonDeserializable<Option<T>> where T <: JusonDeserializable<T>
```
public static func jusonDeserialize(jsonValue: JsonValue): Option<T>
```
将 `JsonValue` 转换成 `Option<T>`，在 `JsonNull` 情况下返回 `None`。

### public interface JsonObjectExtension
用来重载`JsonObject`的`[]`运算符

### extend JsonObjectExtension

#### extend JsonObject <: JsonObjectExtension
```
operator func [](key: String, value!: JusonSerializable)
```
示例：
```
let obj = JsonObject()
obj["key"] = "value"
```
通过`[]`运算符，将继承[`JusonSerializable`](api.md#public-interface-jusonserializable)接口的对象添加到`JsonObject`中。