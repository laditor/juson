protected package json4cj.test

import std.collection.{HashMap, ArrayList}
import json4cj.*

@Test
protected class ToJsonValueTests {
    @TestCase
    func castInt64Test() {
        let input = 42
        let expectedOutput = JsonInt(42)

        let result = input.toJsonValue()

        @Expect(result.toJsonString(), expectedOutput.toJsonString())
    }
    @TestCase
    func castBoolTest() {
        let inputTrue = true
        let expectedOutputTrue = JsonBool(true)

        let resultTrue = inputTrue.toJsonValue()

        @Expect(resultTrue.toJsonString(), expectedOutputTrue.toJsonString())

        let inputFalse = false
        let expectedOutputFalse = JsonBool(false)

        let resultFalse = inputFalse.toJsonValue()

        @Expect(resultFalse.toJsonString(), expectedOutputFalse.toJsonString())
    }

    @TestCase
    func castFloat64Test() {
        let input = 3.14
        let expectedOutput = JsonFloat(3.14)

        let result = input.toJsonValue()

        @Expect(result.toJsonString(), expectedOutput.toJsonString())
    }
    @TestCase
    func castStringTest() {
        let input = "Hello, World!"
        let expectedOutput = JsonString("Hello, World!")

        let result = input.toJsonValue()

        @Expect(result.toJsonString(), expectedOutput.toJsonString())
    }
    @TestCase
    func castArrayTest() {
        let input = [1, 2 , 3]
        let expectedOutput = JsonArray([JsonInt(1), JsonInt(2), JsonInt(3)])

        let result = input.toJsonValue()

        @Expect(result.toJsonString(), expectedOutput.toJsonString())
    }
    @TestCase
    func castArrayListTest() {
        let inputList = ArrayList<Float64>([0.2, 0.5])

        let expectedOutput = JsonArray([JsonFloat(0.2), JsonFloat(0.5)])

        let result = inputList.toJsonValue()

        @Expect(result.toJsonString(), expectedOutput.toJsonString())
    }
    @TestCase
    func castHashMapTest() {
        let inputMap = HashMap<String, Int64>()
        inputMap["key1"] = 123
        inputMap["key2"] = 234
        let input = inputMap

        let expectedOutput = JsonObject(HashMap<String, JsonValue>([("key1", JsonInt(123)), ("key2", JsonInt(234))]))

        let result = input.toJsonValue()

        @Expect(result.toJsonString(), expectedOutput.toJsonString())
    }
    @TestCase
    func castOptionTest() {
        // Test Some
        let inputSome = Some(99)
        let expectedOutputSome = JsonInt(99)

        let resultSome = inputSome.toJsonValue()

        @Expect(resultSome.toJsonString(), expectedOutputSome.toJsonString())

        // Test None
        let inputNone = None<Int64>
        let expectedOutputNone = JsonNull()

        let resultNone = inputNone.toJsonValue()

        @Expect(resultNone.toJsonString(), expectedOutputNone.toJsonString())
    }
}
