protected package juson.test

import std.collection.{HashMap, ArrayList, forEach}
import juson.*

@Test
protected class ToJsonValueTests {
    @TestCase[v in random()]
    func castInt64Test(v: Int64) {
        let input = v
        let expectedOutput = JsonInt(v)

        let result = input.toJsonValue()

        @Expect(result.toJsonString(), expectedOutput.toJsonString())
    }
    @TestCase[v in random()]
    func castBoolTest(v: Bool) {
        let inputTrue = v
        let expectedOutputTrue = JsonBool(v)

        let resultTrue = inputTrue.toJsonValue()

        @Expect(resultTrue.toJsonString(), expectedOutputTrue.toJsonString())

        let inputFalse = false
        let expectedOutputFalse = JsonBool(false)

        let resultFalse = inputFalse.toJsonValue()

        @Expect(resultFalse.toJsonString(), expectedOutputFalse.toJsonString())
    }

    @TestCase[v in random()]
    func castFloat64Test(v: Float64) {
        let input = v
        let expectedOutput = JsonFloat(v)

        let result = input.toJsonValue()

        @Expect(result.toJsonString(), expectedOutput.toJsonString())
    }
    @TestCase[v in random()]
    func castStringTest(v: String) {
        let input = v
        let expectedOutput = JsonString(v)

        let result = input.toJsonValue()

        @Expect(result.toJsonString(), expectedOutput.toJsonString())
    }
    @TestCase[v in random()]
    func castArrayTest(v: Array<Int64>) {
        let input = v
        let expectedOutput = JsonArray()
        v |> forEach{i => expectedOutput.add(JsonInt(i))}

        let result = input.toJsonValue()

        @Expect(result.toJsonString(), expectedOutput.toJsonString())
    }
    @TestCase[v in random()]
    func castArrayListTest(v: ArrayList<Float64>) {
        let inputList = v
        let expectedOutput = JsonArray()
        v |> forEach{i => expectedOutput.add(JsonFloat(i))}

        let result = inputList.toJsonValue()

        @Expect(result.toJsonString(), expectedOutput.toJsonString())
    }
    @TestCase[v in random()]
    func castHashMapTest(v: HashMap<String, Int64>) {
        let input = v

        let expectedOutput = JsonObject()
        v |> forEach {i => expectedOutput.put(i[0], JsonInt(i[1]))}

        let result = input.toJsonValue()

        @Expect(result.toJsonString(), expectedOutput.toJsonString())
    }
    @TestCase[v in random()]
    func castOptionTest(v: Option<Int64>) {
        // Test Some
        let input = v
        let expectedOutputSome = match (v) {
            case Some(s) => JsonInt(s)
            case None => JsonNull()
        }

        let resultSome = input.toJsonValue()

        @Expect(resultSome.toJsonString(), expectedOutputSome.toJsonString())
    }

    @TestCase[v1 in random(), v2 in random(), v3 in random(), v4 in random(),]
    func castJsonValueTest(v1: Bool, v2: Float64, v3: Int64, v4: String) {
        let expectedOutput1 = JsonBool(v1)
        let result1 = expectedOutput1.toJsonValue()
        @Expect(result1.toJsonString(), expectedOutput1.toJsonString())
        
        let expectedOutput2 = JsonFloat(v2)
        let result2 = expectedOutput2.toJsonValue()
        @Expect(result2.toJsonString(), expectedOutput2.toJsonString())

        let expectedOutput3 = JsonInt(v3)
        let result3 = expectedOutput3.toJsonValue()
        @Expect(result3.toJsonString(), expectedOutput3.toJsonString())

        let expectedOutput4 = JsonString(v4)
        let result4 = expectedOutput4.toJsonValue()
        @Expect(result4.toJsonString(), expectedOutput4.toJsonString())

        let expectedOutput5 = JsonArray([expectedOutput1, expectedOutput2])
        let result5 = expectedOutput5.toJsonValue()
        @Expect(result5.toJsonString(), expectedOutput5.toJsonString())

        let expectedOutput6 = JsonObject()
        expectedOutput6.put("bool", expectedOutput1)
        expectedOutput6.put("float", expectedOutput2)
        expectedOutput6.put("int", expectedOutput3)
        expectedOutput6.put("string", expectedOutput4)
        expectedOutput6.put("array", expectedOutput5)
        let result6 = expectedOutput6.toJsonValue()
        @Expect(result6.toJsonString(), expectedOutput6.toJsonString())
    }
}
