package juson.core

import encoding.json.{JsonValue, JsonBool, JsonInt, JsonFloat, JsonString, JsonArray, JsonObject, JsonNull}
import std.collection.{HashMap, TreeMap, ArrayList, map, collectArray}

public interface JusonSerializable {
    func jusonSerialize(): JsonValue
}

extend JsonValue <: JusonSerializable {
    public func jusonSerialize(): JsonValue { this }
}

extend Bool <: JusonSerializable {
    public func jusonSerialize(): JsonBool { JsonBool(this) }
}

extend Int64 <: JusonSerializable {
    public func jusonSerialize(): JsonInt { JsonInt(this) }
}

extend Float64 <: JusonSerializable {
    public func jusonSerialize(): JsonFloat { JsonFloat(this) }
}

extend String <: JusonSerializable {
    public func jusonSerialize(): JsonString { JsonString(this) }
}

extend<T> Array<T> <: JusonSerializable where T <: JusonSerializable {
    public func jusonSerialize(): JsonArray {
        JsonArray(Array(this.size, {i => this[i].jusonSerialize()}))
    }
}

extend<T> ArrayList<T> <: JusonSerializable where T <: JusonSerializable {
    public func jusonSerialize(): JsonArray {
        JsonArray(Array(this.size, {i => this[i].jusonSerialize()}))
    }
}

extend<T> HashMap<String, T> <: JusonSerializable where T <: JusonSerializable {
    public func jusonSerialize(): JsonObject {
        let arr = this.toArray()
        return JsonObject(HashMap(Array(arr.size, {i => (arr[i][0], arr[i][1].jusonSerialize())})))
    }
}

extend<T> TreeMap<String, T> <: JusonSerializable where T <: JusonSerializable {
    public func jusonSerialize(): JsonObject {
        let arr = this.toArray()
        return JsonObject(HashMap(Array(arr.size, {i => (arr[i][0], arr[i][1].jusonSerialize())})))
    }
}

extend<T> Option<T> <: JusonSerializable where T <: JusonSerializable {
    public func jusonSerialize(): JsonValue {
        match (this) {
            case Some(s) => s.jusonSerialize()
            case None => JsonNull()
        }
    }
}

