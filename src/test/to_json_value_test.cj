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
}
