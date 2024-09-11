package juson.core

import encoding.json.{JsonValue, JsonBool, JsonInt, JsonFloat, JsonString, JsonArray, JsonObject, JsonNull}
import std.collection.{HashMap, TreeMap, ArrayList, map, collectArray}
import std.math.numeric.BigInt
import std.time.DateTime

public interface JusonDeserializable<T> {
    static func jusonDeserialize(jsonValue: JsonValue): T
}

extend JsonValue <: JusonDeserializable<JsonValue> {
    public static func jusonDeserialize(jsonValue: JsonValue): JsonValue { jsonValue }
}

extend Bool <: JusonDeserializable<Bool> {
    public static func jusonDeserialize(jsonValue: JsonValue): Bool { jsonValue.asBool().getValue() }
}

extend DateTime <: JusonDeserializable<DateTime> {
    public static func jusonDeserialize(jsonValue: JsonValue): DateTime { DateTime.parse(jsonValue.asString().getValue()) }
}

extend Int64 <: JusonDeserializable<Int64> {
    public static func jusonDeserialize(jsonValue: JsonValue): Int64 { jsonValue.asInt().getValue() }
}

extend Float64 <: JusonDeserializable<Float64> {
    public static func jusonDeserialize(jsonValue: JsonValue): Float64 { jsonValue.asFloat().getValue() }
}

extend String <: JusonDeserializable<String> {
    public static func jusonDeserialize(jsonValue: JsonValue): String { jsonValue.asString().getValue() }

}

extend<T> Array<T> <: JusonDeserializable<Array<T>> where T <: JusonDeserializable<T> {
    public static func jusonDeserialize(jsonValue: JsonValue): Array<T> {
        jsonValue.asArray().getItems() |> map {i => T.jusonDeserialize(i) } |> collectArray
    }
}

extend<T> HashMap<String, T> <: JusonDeserializable<HashMap<String, T>> where T <: JusonDeserializable<T> {
    public static func jusonDeserialize(jsonValue: JsonValue): HashMap<String, T> {
        HashMap(jsonValue.asObject().getFields() |> map { i => (i[0], T.jusonDeserialize(i[1])) } |> collectArray)
    }
}

extend<T> TreeMap<String, T> <: JusonDeserializable<TreeMap<String, T>> where T <: JusonDeserializable<T> {
    public static func jusonDeserialize(jsonValue: JsonValue): TreeMap<String, T> {
        TreeMap(jsonValue.asObject().getFields() |> map { i => (i[0], T.jusonDeserialize(i[1])) } |> collectArray)
    }
}

extend<T> Option<T> <: JusonDeserializable<Option<T>> where T <: JusonDeserializable<T> {
    public static func jusonDeserialize(jsonValue: JsonValue): Option<T> {
        match (jsonValue) {
            case _: JsonNull => None
            case v => T.jusonDeserialize(v) 
        }
    }
}


