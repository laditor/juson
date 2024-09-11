macro package juson

import std.ast.*
import juson.converter.{jsonConverter, jusonConverter, fieldConvertor}
public import std.collection.{collectHashMap}
public import encoding.json.{JsonValue, JsonBool, JsonInt, JsonFloat, JsonString, JsonArray, JsonObject, JsonNull}
public import juson.core.{JusonSerializable, JusonDeserializable}
public import juson.exception.{SerializationException, DeserializationException}

// json字面量宏
public macro Json(input: Tokens): Tokens {
    jsonConverter(input)
}

// 类/结构体自动序列化/反序列化
public macro Juson(input: Tokens): Tokens {
    jusonConverter(input)
}

// 设置字段的序列化/反序列化相关属性
public macro Field(attrs: Tokens, input: Tokens) {
    fieldConvertor(attrs, input)
}