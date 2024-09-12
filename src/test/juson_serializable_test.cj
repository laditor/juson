protected package juson.test

import std.collection.{HashMap, TreeMap, ArrayList, forEach}
import std.time.DateTime
import std.math.numeric.{BigInt, Decimal}
import juson.*

@Test
protected class JusonSerializableTests {
    @TestCase[v in random<Int64>()]
    func serializeInt64TestT(v: Int64) {
        let expectedOutput = JsonInt(v)
        let result = v.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }

    @TestCase[v in random<Int32>()]
    func serializeInt32TestT(v: Int32) {
        let expectedOutput = JsonInt(Int64(v))
        let result = v.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }

    @TestCase[v in random<Int16>()]
    func serializeInt16TestT(v: Int16) {
        let expectedOutput = JsonInt(Int64(v))
        let result = v.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }

    @TestCase[v in random<Int8>()]
    func serializeInt8TestT(v: Int8) {
        let expectedOutput = JsonInt(Int64(v))
        let result = v.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }

    @TestCase[v in random<IntNative>()]
    func serializeIntNativeTestT(v: IntNative) {
        let expectedOutput = JsonInt(Int64(v))
        let result = v.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }

    @TestCase[v in random<UInt64>()]
    func serializeUInt64TestT(v: UInt64) {
        if (v > UInt64(Int64.Max)) {
            @ExpectThrows({
                JsonInt(Int64(v))
            })
            @ExpectThrows({
                v.jusonSerialize()
            })
        } else {
            let expectedOutput = JsonInt(Int64(v))
            let result = v.jusonSerialize()
            @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
        }
    }

    @TestCase[v in random<UInt32>()]
    func serializeUInt32TestT(v: UInt32) {
        let expectedOutput = JsonInt(Int64(v))
        let result = v.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }   

    @TestCase[v in random<UInt16>()]
    func serializeUInt16TestT(v: UInt16) {
        let expectedOutput = JsonInt(Int64(v))
        let result = v.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }

    @TestCase[v in random<UInt8>()]
    func serializeUInt8TestT(v: UInt8) {
        let expectedOutput = JsonInt(Int64(v))
        let result = v.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }

    @TestCase[v in random<UIntNative>()]
    func serializeUIntNativeTestT(v: UIntNative) {
        if (UInt64(v) > UInt64(Int64.Max)) {
            @ExpectThrows({
                JsonInt(Int64(v))
            })
            @ExpectThrows({
                v.jusonSerialize()
            })
        } else {
            let expectedOutput = JsonInt(Int64(v))
            let result = v.jusonSerialize()
            @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
        }
    }

    @TestCase[v in [true, false]]
    func serializeBoolTest(v: Bool) {
        let expectedOutput = JsonBool(v)
        let result = v.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }

    @TestCase[v in random<Float64>()]
    func serializeFloat64Test(v: Float64) {
        let expectedOutput = JsonFloat(v)
        let result = v.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }

    @TestCase[v in random<Float32>()]
    func serializeFloat32Test(v: Float32) {
        let expectedOutput = JsonFloat(Float64(v))
        let result = v.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }

    @TestCase[v in random<Float16>()]
    func serializeFloat16Test(v: Float16) {
        let expectedOutput = JsonFloat(Float64(v))
        let result = v.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }

    @TestCase[v in random<String>()]
    func serializeStringTest(v: String) {
        let expectedOutput = JsonString(v)
        let result = v.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }

    @TestCase[v in random<Array<Int64>>()]
    func serializeArrayTest(v: Array<Int64>) {
        let expectedOutput = JsonArray()
        v |> forEach {i => expectedOutput.add(JsonInt(i))}
        let result = v.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }

    @TestCase[v in random<ArrayList<Float64>>()]
    func serializeArrayListTest(v: ArrayList<Float64>) {
        let expectedOutput = JsonArray()
        v |> forEach {i => expectedOutput.add(JsonFloat(i))}
        let result = v.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }

    @TestCase[v in random<HashMap<String, Int64>>()]
    func serializeHashMapTest(v: HashMap<String, Int64>) {
        let expectedOutput = JsonObject()
        v |> forEach {i => expectedOutput.put(i[0], JsonInt(i[1]))}
        let result = v.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }

    @TestCase[v in random<HashMap<String, Int64>>()]
    func serializeTreeMapTest(v: HashMap<String, Int64>) {
        let expectedOutput = JsonObject()
        v |> forEach {i => expectedOutput.put(i[0], JsonInt(i[1]))}
        let result = HashMap(v).jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }

    @TestCase[v in random<Int64>()]
    func serializeOptionTest(v: Int64) {
        let v1 = Some(v)
        let expectedOutput = JsonInt(v1.getOrThrow())
        let result = v1.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())

        let v2 = None<Int64>
        let expectedOutput2 = JsonNull()
        let result2 = v2.jusonSerialize()
        @Expect(result2.jusonSerialize().toJsonString(), expectedOutput2.jusonSerialize().toJsonString())
    }

    @TestCase[secondNumber in random<Int32>()]
    func serializeDataTimeTest(secondNumber: Int32) {
        let time = DateTime.fromUnixTimeStamp(Duration.second * Int64(secondNumber))
        let expectedOutput = JsonString(time.toString())
        let result = time.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }

    @TestCase[sign in random<Bool>(), bitLen in (1..Int64.Max)]
    func serializeBigIntTest(sign: Bool, bitLen: Int64) {
        let v = BigInt(sign, bitLen)
        let expectedOutput = JsonString(v.toString())
        let result = v.jusonSerialize()
        @Expect(result.jusonSerialize().toJsonString(), expectedOutput.jusonSerialize().toJsonString())
    }

    @TestCase[integer in (0..Int64.Max), fraction in random<Int64>()]
    func serializeDecimalTest(integer : Int64, fraction: Int64) {
        let v1 = Decimal(integer)
        let expectedOutput1 = JsonString(v1.toString())
        let result1 = v1.jusonSerialize()
        @Expect(result1.jusonSerialize().toJsonString(), expectedOutput1.jusonSerialize().toJsonString())

        let v2 = Decimal(fraction)
        let expectedOutput2 = JsonString(v2.toString())
        let result2 = v2.jusonSerialize()
        @Expect(result2.jusonSerialize().toJsonString(), expectedOutput2.jusonSerialize().toJsonString())
    }

    @TestCase[
        v1 in random<Bool>(),
        v2 in random<Float64>(),
        v3 in random<Int64>(),
        v4 in random<String>()
    ]
    func serializeJsonValueTest(v1: Bool, v2: Float64, v3: Int64, v4: String) {
        let expectedOutput1 = JsonBool(v1)
        let result1 = expectedOutput1.jusonSerialize()
        @Expect(result1.jusonSerialize().toJsonString(), expectedOutput1.jusonSerialize().toJsonString())

        let expectedOutput2 = JsonFloat(v2)
        let result2 = expectedOutput2.jusonSerialize()
        @Expect(result2.jusonSerialize().toJsonString(), expectedOutput2.jusonSerialize().toJsonString())

        let expectedOutput3 = JsonInt(v3)
        let result3 = expectedOutput3.jusonSerialize()
        @Expect(result3.jusonSerialize().toJsonString(), expectedOutput3.jusonSerialize().toJsonString())

        let expectedOutput4 = JsonString(v4)
        let result4 = expectedOutput4.jusonSerialize()
        @Expect(result4.jusonSerialize().toJsonString(), expectedOutput4.jusonSerialize().toJsonString())

        let expectedOutput5 = JsonArray([expectedOutput1, expectedOutput2])
        let result5 = expectedOutput5.jusonSerialize()
        @Expect(result5.jusonSerialize().toJsonString(), expectedOutput5.jusonSerialize().toJsonString())

        let expectedOutput6 = JsonObject()
        expectedOutput6.put("bool", expectedOutput1)
        expectedOutput6.put("float", expectedOutput2)
        expectedOutput6.put("int", expectedOutput3)
        expectedOutput6.put("string", expectedOutput4)
        expectedOutput6.put("array", expectedOutput5)
        let result6 = expectedOutput6.jusonSerialize()
        @Expect(result6.jusonSerialize().toJsonString(), expectedOutput6.jusonSerialize().toJsonString())
    }
}
