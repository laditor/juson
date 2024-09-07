protected package juson.test

import juson.*

@Test
public class JsonTests {
    // Test String values
    @TestCase[
        v1 in random(),
        v2 in random(),
        v3 in [true, false],
    ]
    func jsonValueTest(v1: Int64, v2: String, v3: Bool) {
        let o1 = JsonInt(v1)
        let j1 = @Json(v1)
        @Expect(o1.toJsonString(), j1.toJsonString())

        let o2 = JsonString(v2)
        let j2 = @Json(v2)
        @Expect(o2.toJsonString(), j2.toJsonString())

        let o3 = JsonBool(v3)
        let j3 = @Json(v3)
        @Expect(o3.toJsonString(), j3.toJsonString())

        let o4 = JsonNull()
        let j4 = @Json(null)
        @Expect(j4.toJsonString(), o4.toJsonString())
    }
    @TestCase
    func jsonStringTest() {
        let o = JsonObject.fromStr(
            #"{
            "simpleString": "simple",
            "name": "kiiiia",
            "specialString": "Hello\nWorld\t!"
        }"#
        )
        let name = "kiiiia"
        let str = "simple"
        let j = @Json(
            {
            "simpleString": str,
            "name": name,
            "specialString": "Hello\nWorld\t!"
            }
        )
        @Expect(o.toJsonString(), j.toJsonString())
    }

    // Test Number values
    @TestCase
    func jsonNumberTest() {
        let o = JsonObject.fromStr(#"{
            "integer": 42,
            "float": 3.14
        }"#)
        let intVal = 42
        let floatVal = 3.14
        let j = @Json(
            {
            "integer": intVal,
            "float": floatVal
            }
        )
        @Expect(o.toJsonString(), j.toJsonString())
    }

    // Test Boolean values
    @TestCase
    func jsonBooleanTest() {
        let o = JsonObject.fromStr(#"{
            "trueValue": true,
            "falseValue": false
        }"#)
        let j = @Json(
            {
            "trueValue": true,
            "falseValue": false
            }
        )
        @Expect(o.toJsonString(), j.toJsonString())
    }

    // Test Null values
    @TestCase
    func jsonNullTest() {
        let o = JsonObject.fromStr(#"{
            "nullValue": null
        }"#)
        let j = @Json(
            {
            "nullValue": null
            }
        )
        @Expect(o.toJsonString(), j.toJsonString())
    }

    // Test Arrays
    @TestCase
    func jsonArrayTest() {
        let o = JsonObject.fromStr(
            #"{
            "array": [1, "string", true, null, {"key": "value"}],
            "array1": [1, 2, "string"]
        }"#
        )
        let str = "string"
        let j = @Json(
            {
            "array": [1, "string", true, null, {"key": "value"}],
            "array1": [1, 2, str],
            }
        )
        @Expect(o.toJsonString(), j.toJsonString())
    }

    // Test Nested Objects
    @TestCase
    func jsonNestedObjectTest() {
        let o = JsonObject.fromStr(
            #"{
            "nestedObject": {
                "innerObject": {
                    "key": "value"
                }
            }
        }"#
        )
        let j = @Json(
            {
            "nestedObject": {
                "innerObject": {
                    "key": "value"
                }
            }
            }
        )
        @Expect(o.toJsonString(), j.toJsonString())
    }

    // Test Special Characters
    @TestCase
    func jsonSpecialCharactersTest() {
        let o = JsonObject.fromStr(#"{
            "specialString": "Hello\nWorld\t!\\"
        }"#)
        let specialStr = "Hello\nWorld\t!\\"
        let j = @Json(
            {
            "specialString": specialStr
            }
        )
        @Expect(o.toJsonString(), j.toJsonString())
    }

    // Test Dynamic Keys and Values
    @TestCase
    func jsonDynamicKeyTest() {
        let o = JsonObject.fromStr(
            #"{
            "dynamicKey": "dynamicValue",
            "dynamicKey1": "dynamicValue1",
            "dynamicKeydynamicKey": "dynamicValuedynamicValue",
            "[dynamicKey]": "[dynamicValue]",
            "dynamicKey-ofStr2": "dynamicValue-ofStr2"
        }"#
        )
        let dynamicKey = "dynamicKey"
        let dynamicValue = "dynamicValue"
        let ofStr1 = {s: String => "[${s}]"}
        let ofStr2 = {s: String => "${s}-ofStr2"}
        let j = @Json(
            {
            dynamicKey: dynamicValue,
            dynamicKey + "1": dynamicValue + "1",
            dynamicKey*2: dynamicValue*2,
            ofStr1(dynamicKey): ofStr1(dynamicValue),
            dynamicKey |> 
                ofStr2: dynamicValue |> 
                    ofStr2
            }
        )
        @Expect(o.toJsonString(), j.toJsonString())
    }

    // Test Trailing Commas
    @TestCase
    func jsonTrailingCommaTest() {
        let o = JsonObject.fromStr(
            #"{
            "key1": {
                "key12": "value12",
                "key12": "value12"
            },
            "key2": [
                "value21",
                "value22"
            ]
            }"#
        )
        let j = @Json(
            {
            "key1": {
                "key12": "value12",
                "key12": "value12",
            },
            "key2": [
                "value21",
                "value22",
            ],
            }
        )
        @Expect(o.toJsonString(), j.toJsonString())
    }

    @TestCase
    func jsonNestedDynamicTest() {
        let jInt = @Json(-5 * -18)
        let jFloat = @Json(3.5 * -1.9)
        let jString = @Json("jsodfns")
        let j1 = @Json(
            {
                "name": jString,
                "num": jInt
            }
        )
        let j2 = @Json([
            jString, jFloat
        ])
        let j3 = @Json({
            "json1": j1,
            "json2": j2
        })
        let o3 = JsonObject()
        let o3InnerObject = JsonObject()
        o3InnerObject.put("name", JsonString("inner object"))
        o3InnerObject.put("num", JsonInt(0))
        o3.put("json1", o3InnerObject)
        o3.put("json2", JsonArray([JsonString("inner array"), JsonInt(1)]))

        @Expect(o3.toJsonString(), j3.toJsonString())

        let j4 = @Json({
            "json1": @Json({
                "name": "inner object",
                "num": 0
            }),
            "json2": @Json([
                "inner array",
                1
            ])
        })
        @Expect(o3.toJsonString(), j4.toJsonString())
    }
}

