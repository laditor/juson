macro package json4cj

import std.ast.*
import json4cj.parser.JsonParser
public import json4cj.ext._castJsonValue

public macro Json(input: Tokens): Tokens {
    JsonParser(input).parseWhole()
}