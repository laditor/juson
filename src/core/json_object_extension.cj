package juson.core

import encoding.json.JsonObject

public interface JsonObjectExtension {}

extend JsonObject<: JsonObjectExtension {
    public operator func [](key: String, value!: JusonSerializable) {
        this.put(key, value.jusonSerialize())
    }
}