package juson.exception

public class SerializationException <: Exception {
    public init() {
        super()
    }
    public init(message: String) {
        super(message)
    }
}

public class DeserializationException <: Exception {
    public init() {
        super()
    }
    public init(message: String) {
        super(message)
    }
}