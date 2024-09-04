protected package json4cj.test

import encoding.json.*
import json4cj.*

@Test
public class JsonTest {
    // Test String values
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
        let o = JsonObject.fromStr(#"{
            "array": [1, "string", true, null, {"key": "value"}]
        }"#)
        let j = @Json(
            {
            "array": [1, "string", true, null, {"key": "value"}]
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
        let o = JsonObject.fromStr(#"{
            "dynamicKey": "dynamicValue",
            "dynamicKey1": "dynamicValue1",
            "dynamicKeydynamicKey": "dynamicValuedynamicValue",
            "[dynamicKey]": "[dynamicValue]",
            "dynamicKey-ofStr2": "dynamicValue-ofStr2"
        }"#)
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
            dynamicKey |> ofStr2: dynamicValue |> ofStr2
            }
        )
        @Expect(o.toJsonString(), j.toJsonString())
    }

    // Test Trailing Commas
    @TestCase
    func jsonTrailingCommaTest() {
        let o = JsonObject.fromStr(#"{
            "key1": {
                "key12": "value12",
                "key12": "value12"
            },
            "key2": [
                "value21",
                "value22"
            ]
            }"#)
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
}
