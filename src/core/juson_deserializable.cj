package juson.core

import encoding.json.{JsonValue, JsonBool, JsonInt, JsonFloat, JsonString, JsonArray, JsonObject, JsonNull}
import std.collection.{HashMap, TreeMap, ArrayList, map, collectArray, collectArrayList}
import std.math.numeric.{BigInt, Decimal}
import std.time.DateTime

public interface JusonDeserializable<T> {
    static func jusonDeserialize(jsonValue: JsonValue): T
}

extend JsonValue <: JusonDeserializable<JsonValue> {
    public static func jusonDeserialize(jsonValue: JsonValue): JsonValue { jsonValue }
}

extend BigInt <: JusonDeserializable<BigInt> {
    public static func jusonDeserialize(jsonValue: JsonValue): BigInt { BigInt(jsonValue.asString().getValue())}
}

extend DateTime <: JusonDeserializable<DateTime> {
    public static func jusonDeserialize(jsonValue: JsonValue): DateTime { DateTime.parse(jsonValue.asString().getValue()) }
    public static func jusonDeserialize(jsonValue: JsonValue, format: String): DateTime { DateTime.parse(jsonValue.asString().getValue(), format) }
}

extend Decimal <: JusonDeserializable<Decimal> {
    public static func jusonDeserialize(jsonValue: JsonValue): Decimal { Decimal(jsonValue.asString().getValue()) }
}

extend Bool <: JusonDeserializable<Bool> {
    public static func jusonDeserialize(jsonValue: JsonValue): Bool { jsonValue.asBool().getValue() }
}

extend Int8 <: JusonDeserializable<Int8> {
    public static func jusonDeserialize(jsonValue: JsonValue): Int8 { Int8(jsonValue.asInt().getValue()) }
}

extend Int16 <: JusonDeserializable<Int16> {
    public static func jusonDeserialize(jsonValue: JsonValue): Int16 { Int16(jsonValue.asInt().getValue()) }
}

extend Int32 <: JusonDeserializable<Int32> {
    public static func jusonDeserialize(jsonValue: JsonValue): Int32 { Int32(jsonValue.asInt().getValue()) }
}

extend Int64 <: JusonDeserializable<Int64> {
    public static func jusonDeserialize(jsonValue: JsonValue): Int64 { jsonValue.asInt().getValue() }
}

extend IntNative <: JusonDeserializable<IntNative> {
    public static func jusonDeserialize(jsonValue: JsonValue): IntNative { IntNative(jsonValue.asInt().getValue()) }
}

extend UInt8 <: JusonDeserializable<UInt8> {
    public static func jusonDeserialize(jsonValue: JsonValue): UInt8 { UInt8(jsonValue.asInt().getValue()) }
}

extend UInt16 <: JusonDeserializable<UInt16> {
    public static func jusonDeserialize(jsonValue: JsonValue): UInt16 { UInt16(jsonValue.asInt().getValue()) }
}

extend UInt32 <: JusonDeserializable<UInt32> {
    public static func jusonDeserialize(jsonValue: JsonValue): UInt32 { UInt32(jsonValue.asInt().getValue()) }
}

extend UInt64 <: JusonDeserializable<UInt64> {
    public static func jusonDeserialize(jsonValue: JsonValue): UInt64 { UInt64(jsonValue.asInt().getValue()) }
}

extend UIntNative <: JusonDeserializable<UIntNative> {
    public static func jusonDeserialize(jsonValue: JsonValue): UIntNative { UIntNative(jsonValue.asInt().getValue()) }
}

extend Float16 <: JusonDeserializable<Float16> {
    public static func jusonDeserialize(jsonValue: JsonValue): Float16 { Float16(jsonValue.asFloat().getValue()) }
}

extend Float32 <: JusonDeserializable<Float32> {
    public static func jusonDeserialize(jsonValue: JsonValue): Float32 { Float32(jsonValue.asFloat().getValue()) }
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

extend<T> ArrayList<T> <: JusonDeserializable<ArrayList<T>> where T <: JusonDeserializable<T> {
    public static func jusonDeserialize(jsonValue: JsonValue): ArrayList<T> {
        jsonValue.asArray().getItems() |> map {i => T.jusonDeserialize(i) } |> collectArrayList
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


