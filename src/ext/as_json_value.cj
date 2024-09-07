package juson.ext

import encoding.json.*
import std.collection.{ArrayList, HashMap, TreeMap, reduce}

public interface ToJsonValue  {
    func toJsonValue(): JsonValue
}

extend Bool <: ToJsonValue {
    public func toJsonValue(): JsonBool { JsonBool(this) }
}

extend Float64 <: ToJsonValue {
    public func toJsonValue(): JsonFloat { JsonFloat(this) }
}

extend Int64 <: ToJsonValue {
    public func toJsonValue(): JsonInt { JsonInt(this) }
}

extend String <: ToJsonValue {
    public func toJsonValue(): JsonString { JsonString(this) }
}

extend<T> Array<T> <: ToJsonValue where T <: ToJsonValue {
    public func toJsonValue(): JsonArray { 
        JsonArray(Array(this.size, {i => this[i].toJsonValue()}))
    }
}

extend<T> ArrayList<T> <: ToJsonValue where T <: ToJsonValue {
    public func toJsonValue(): JsonArray {
        JsonArray(Array(this.size, {i => this[i].toJsonValue()}))
    }
}

extend<T> TreeMap<String, T> <: ToJsonValue where T <: ToJsonValue {
    public func toJsonValue(): JsonObject {
        let arr = this.toArray()
        JsonObject(HashMap(Array(this.size, {i => (arr[i][0], arr[i][1].toJsonValue())})))
    }
}

extend<T> HashMap<String, T> <: ToJsonValue where T <: ToJsonValue {
    public func toJsonValue(): JsonObject {
        let arr = this.toArray()
        JsonObject(HashMap(Array(this.size, {i => (arr[i][0], arr[i][1].toJsonValue())})))
    }
}

extend<T> Option<T> <: ToJsonValue where T <: ToJsonValue {
    public func toJsonValue(): JsonValue {
        match (this) {
            case Some(s) => s.toJsonValue()
            case None => JsonNull()
        }
    }
}

extend JsonValue <: ToJsonValue {
    public func toJsonValue(): JsonValue { this }
}

extend JsonBool {
    public func ToJsonValue(): JsonBool { this }
}

extend JsonFloat {
    public func ToJsonValue(): JsonFloat { this }
}

extend JsonInt {
    public func ToJsonValue(): JsonInt { this }
}

extend JsonString {
    public func ToJsonValue(): JsonString { this }
}

extend JsonNull {
    public func ToJsonValue(): JsonNull { this }
}

extend JsonArray {
    public func ToJsonValue(): JsonArray { this }
}

extend JsonObject {
    public func ToJsonValue(): JsonObject { this }
}