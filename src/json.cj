macro package json4cj

import std.ast.*
import json4cj.parser.parseWhole
public import encoding.json.*
public import std.collection.HashMap
public import json4cj.ext.ToJsonValue

public macro Json(input: Tokens): Tokens {
    parseWhole(input)
}