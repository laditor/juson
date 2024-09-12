package juson.core

import encoding.json.{JsonValue, JsonBool, JsonInt, JsonFloat, JsonString, JsonArray, JsonObject, JsonNull}
import std.collection.{HashMap, TreeMap, ArrayList, map, collectArray}
import std.collection.collectHashMap
import std.math.numeric.{BigInt, Decimal}
import std.time.DateTime

public interface JusonSerializable {
    func jusonSerialize(): JsonValue
}

extend JsonValue <: JusonSerializable {
    public func jusonSerialize(): JsonValue { this }
}

extend BigInt <: JusonSerializable {
    public func jusonSerialize(): JsonString { JsonString(this.toString()) }
}

extend DateTime <: JusonSerializable {
    public func jusonSerialize(): JsonString { JsonString(this.toString()) }
    public func jusonSerialize(format: String): JsonString { JsonString(this.toString(format)) }
}

extend Decimal <: JusonSerializable {
    public func jusonSerialize(): JsonString { JsonString(this.toString()) }
}

extend Bool <: JusonSerializable {
    public func jusonSerialize(): JsonBool { JsonBool(this) }
}

extend Int8 <: JusonSerializable {
    public func jusonSerialize(): JsonInt { JsonInt(Int64(this)) }
}

extend Int16 <: JusonSerializable {
    public func jusonSerialize(): JsonInt { JsonInt(Int64(this)) }
}

extend Int32 <: JusonSerializable {
    public func jusonSerialize(): JsonInt { JsonInt(Int64(this)) }
}

extend Int64 <: JusonSerializable {
    public func jusonSerialize(): JsonInt { JsonInt(this) }
}

extend IntNative <: JusonSerializable {
    public func jusonSerialize(): JsonInt { JsonInt(Int64(this)) }
}

extend UInt8 <: JusonSerializable {
    public func jusonSerialize(): JsonInt { JsonInt(Int64(this)) }
}

extend UInt16 <: JusonSerializable {
    public func jusonSerialize(): JsonInt { JsonInt(Int64(this)) }
}

extend UInt32 <: JusonSerializable {
    public func jusonSerialize(): JsonInt { JsonInt(Int64(this)) }
}

extend UInt64 <: JusonSerializable {
    public func jusonSerialize(): JsonInt { JsonInt(Int64(this)) }
}

extend UIntNative <: JusonSerializable {
    public func jusonSerialize(): JsonInt { JsonInt(Int64(this)) }
}

extend Float16 <: JusonSerializable {
    public func jusonSerialize(): JsonFloat { JsonFloat(Float64(this)) }
}

extend Float32 <: JusonSerializable {
    public func jusonSerialize(): JsonFloat { JsonFloat(Float64(this)) }
}

extend Float64 <: JusonSerializable {
    public func jusonSerialize(): JsonFloat { JsonFloat(this) }
}

extend String <: JusonSerializable {
    public func jusonSerialize(): JsonString { JsonString(this) }
}

extend<T> Array<T> <: JusonSerializable where T <: JusonSerializable {
    public func jusonSerialize(): JsonArray {
        JsonArray(this.map{i => i.jusonSerialize()})
    }
}

extend<T> ArrayList<T> <: JusonSerializable where T <: JusonSerializable {
    public func jusonSerialize(): JsonArray {
        JsonArray(this.toArray().map{i => i.jusonSerialize()})
    }
}

extend<T> HashMap<String, T> <: JusonSerializable where T <: JusonSerializable {
    public func jusonSerialize(): JsonObject {
        return JsonObject(this.toArray().map{i => (i[0], i[1].jusonSerialize())} |> collectHashMap)
    }
}

extend<T> TreeMap<String, T> <: JusonSerializable where T <: JusonSerializable {
    public func jusonSerialize(): JsonObject {
        return JsonObject(this.toArray().map{i => (i[0], i[1].jusonSerialize())} |> collectHashMap)
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

