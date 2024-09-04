package json4cj.ext

import encoding.json.*
import std.collection.{ArrayList, HashMap, reduce}

sealed interface AsJsonValue {}

extend Bool <: AsJsonValue {}

extend Float64 <: AsJsonValue {}

extend Int64 <: AsJsonValue {}

extend String <: AsJsonValue {}

extend<T> Array<T> <: AsJsonValue where T <: AsJsonValue {}

extend<T> HashMap<String, T> <: AsJsonValue where T <: AsJsonValue {}

extend<T> ArrayList<T> <: AsJsonValue where T <: AsJsonValue {}

extend<T> Option<T> <: AsJsonValue where T <: AsJsonValue {}

public func _castJsonValue(value: AsJsonValue): JsonValue {
    match (value) {
        case v: Int64 => JsonInt(v)
        case v: Bool => JsonBool(v)
        case v: Float64 => JsonFloat(v)
        case v: String => JsonString(v)
        case v: Array<AsJsonValue> => JsonArray(Array(v.size, {i => v[i] |> _castJsonValue}))
        case v: ArrayList<AsJsonValue> => JsonArray(Array(v.size, {i => v[i] |> _castJsonValue}))
        case v: HashMap<String, AsJsonValue> =>
            let arr = v.toArray()
            JsonObject(HashMap(Array(v.size, {i => (arr[i][0], arr[i][1] |> _castJsonValue)})))
        case v: Option<AsJsonValue> => match (v) {
            case Some(s) => s |> _castJsonValue
            case None => JsonNull()
        }
        case _ => throw Exception("_castJsonValue on unexpected value")
    }
}
