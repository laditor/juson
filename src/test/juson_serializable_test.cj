protected package juson.test

import std.collection.{HashMap, ArrayList, forEach}
import juson.*

@Test
protected class JusonSerializableTests {
    @TestCase[v in random()]
    func castInt64Test(v: Int64) {
        let input = v
        let expectedOutput = JsonInt(v)

        let result = input.jusonSerialize()

        @Expect(result.jusonSerialize(), expectedOutput.jusonSerialize())
    }
    @TestCase[v in random()]
    func castBoolTest(v: Bool) {
        let inputTrue = v
        let expectedOutputTrue = JsonBool(v)

        let resultTrue = inputTrue.jusonSerialize()

        @Expect(resultTrue.jusonSerialize(), expectedOutputTrue.jusonSerialize())

        let inputFalse = false
        let expectedOutputFalse = JsonBool(false)

        let resultFalse = inputFalse.jusonSerialize()

        @Expect(resultFalse.jusonSerialize(), expectedOutputFalse.jusonSerialize())
    }

    @TestCase[v in random()]
    func castFloat64Test(v: Float64) {
        let input = v
        let expectedOutput = JsonFloat(v)

        let result = input.jusonSerialize()

        @Expect(result.jusonSerialize(), expectedOutput.jusonSerialize())
    }
    @TestCase[v in random()]
    func castStringTest(v: String) {
        let input = v
        let expectedOutput = JsonString(v)

        let result = input.jusonSerialize()

        @Expect(result.jusonSerialize(), expectedOutput.jusonSerialize())
    }
    @TestCase[v in random()]
    func castArrayTest(v: Array<Int64>) {
        let input = v
        let expectedOutput = JsonArray()
        v |> forEach{i => expectedOutput.add(JsonInt(i))}

        let result = input.jusonSerialize()

        @Expect(result.jusonSerialize(), expectedOutput.jusonSerialize())
    }
    @TestCase[v in random()]
    func castArrayListTest(v: ArrayList<Float64>) {
        let inputList = v
        let expectedOutput = JsonArray()
        v |> forEach{i => expectedOutput.add(JsonFloat(i))}

        let result = inputList.jusonSerialize()

        @Expect(result.jusonSerialize(), expectedOutput.jusonSerialize())
    }
    @TestCase[v in random()]
    func castHashMapTest(v: HashMap<String, Int64>) {
        let input = v

        let expectedOutput = JsonObject()
        v |> forEach {i => expectedOutput.put(i[0], JsonInt(i[1]))}

        let result = input.jusonSerialize()

        @Expect(result.jusonSerialize(), expectedOutput.jusonSerialize())
    }
    @TestCase[v in random()]
    func castOptionTest(v: Option<Int64>) {
        // Test Some
        let input = v
        let expectedOutputSome = match (v) {
            case Some(s) => JsonInt(s)
            case None => JsonNull()
        }

        let resultSome = input.jusonSerialize()

        @Expect(resultSome.jusonSerialize(), expectedOutputSome.jusonSerialize())
    }

    @TestCase[v1 in random(), v2 in random(), v3 in random(), v4 in random(),]
    func castJsonValueTest(v1: Bool, v2: Float64, v3: Int64, v4: String) {
        let expectedOutput1 = JsonBool(v1)
        let result1 = expectedOutput1.jusonSerialize()
        @Expect(result1.jusonSerialize(), expectedOutput1.jusonSerialize())
        
        let expectedOutput2 = JsonFloat(v2)
        let result2 = expectedOutput2.jusonSerialize()
        @Expect(result2.jusonSerialize(), expectedOutput2.jusonSerialize())

        let expectedOutput3 = JsonInt(v3)
        let result3 = expectedOutput3.jusonSerialize()
        @Expect(result3.jusonSerialize(), expectedOutput3.jusonSerialize())

        let expectedOutput4 = JsonString(v4)
        let result4 = expectedOutput4.jusonSerialize()
        @Expect(result4.jusonSerialize(), expectedOutput4.jusonSerialize())

        let expectedOutput5 = JsonArray([expectedOutput1, expectedOutput2])
        let result5 = expectedOutput5.jusonSerialize()
        @Expect(result5.jusonSerialize(), expectedOutput5.jusonSerialize())

        let expectedOutput6 = JsonObject()
        expectedOutput6.put("bool", expectedOutput1)
        expectedOutput6.put("float", expectedOutput2)
        expectedOutput6.put("int", expectedOutput3)
        expectedOutput6.put("string", expectedOutput4)
        expectedOutput6.put("array", expectedOutput5)
        let result6 = expectedOutput6.jusonSerialize()
        @Expect(result6.jusonSerialize(), expectedOutput6.jusonSerialize())
    }
}
