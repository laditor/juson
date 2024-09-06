macro package juson

import std.ast.*
import juson.parser.parseWhole
public import encoding.json.*
public import std.collection.HashMap
public import juson.ext.ToJsonValue

public macro Json(input: Tokens): Tokens {
    parseWhole(input)
}