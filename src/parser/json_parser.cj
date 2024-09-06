package json4cj.parser

import std.ast.*
import std.collection.{ArrayList, reduce}

protected enum JsonParserState {
    | Init
    | ExpectJsonValue
    | ExpectKeyValuePair
    | ExpectComma
    | JsonArrayStart
    | JsonArrayEnd
    | JsonObjectStart
    | JsonObjectEnd
}

protected func parseWhole(input: Tokens): Tokens {
    let result: Tokens
    var currPos = 0
    currPos = skipWhiteSpace(input, currPos)
    (result, currPos) = parseValue(input, 0)
    if (currPos != input.size) {
        diagReport(DiagReportLevel.ERROR, input[currPos..], 'Excepted no more data here',
            'Unexpected trailing data after JSON value')
        throw ASTException('Unexpected trailing data after JSON value')
    }
    result
}

// 可以直接解析为Json值的Token用parseJsonValue处理，其他的表达式/变量调用toJsonValue()
func parseValue(input: Tokens, pos: Int64): (Tokens, Int64) {
    match (peekExprFragment(input, pos)) {
        // 特殊规则：遇到 [ 统一视为jsonArray，因为语法与Array字面量冲突。在宏中请用Array<T>()
        case Some((expr, index)) where input[pos].kind == LSQUARE => 
            parseJsonValue(input, pos)
        // 长度>=2的表达式一定不是纯json值
        case Some((expr, index)) where expr.size > 1 => 
            (quote(($(expr)).toJsonValue()), index)
        // 长度==1，且Token类型是 IDENTIFIER(非null) / this 的表达式一定不是纯json值
        case Some((expr, index)) => match (expr[0].kind) {
            case THIS => (quote(($(expr)).toJsonValue()), index)
            case IDENTIFIER where input[pos].value != "null" => 
                (quote(($(expr)).toJsonValue()), index)
            case _ => parseJsonValue(input, pos)
        }
        case _ => parseJsonValue(input, pos)
    }
}

func parseJsonValue(input: Tokens, pos: Int64): (Tokens, Int64) {
    var currPos = pos
    currPos = skipWhiteSpace(input, currPos + 1)
    match (input[pos].kind) {
        case STRING_LITERAL => (quote(JsonString($(input[pos]))), currPos)
        case INTEGER_LITERAL => (quote(JsonInt($(input[pos]))), currPos)
        case FLOAT_LITERAL => (quote(JsonFloat($(input[pos]))), currPos)
        case IDENTIFIER where input[pos].value == "null" => (quote(JsonNull()), currPos)
        case BOOL_LITERAL => (quote(JsonBool($(input[pos]))), currPos)
        case LSQUARE => parseArray(input, pos)
        case LCURL => parseObject(input, pos)
        case _ =>
            diagReport(DiagReportLevel.ERROR, input[pos..(pos + 1)], 'Expected json value, found "${input[pos].value}"',
                'Failed to parse "${input[pos].value}"')
            throw ASTException('Failed to parse "${input[pos].value}"')
    }
}

func parseArray(input: Tokens, pos: Int64): (Tokens, Int64) {
    var currPos = pos
    var state = JsonParserState.Init
    var isParsing = true
    let list = ArrayList<Tokens>()
    while (currPos < input.size && isParsing) {
        match (state) {
            case Init =>
                currPos = conformNext(input, currPos, LSQUARE)
                state = JsonArrayStart
            case JsonArrayStart => if (input[currPos].kind == RSQUARE) {
                state = JsonArrayEnd
            } else {
                state = ExpectJsonValue
            }
            case ExpectJsonValue =>
                let tks: Tokens
                (tks, currPos) = parseValue(input, currPos)
                list.append(tks)
                if (input[currPos].kind == RSQUARE) {
                    state = JsonArrayEnd
                } else {
                    state = ExpectComma
                }
            case ExpectComma =>
                currPos = skipComma(input, currPos)
                if (input[currPos].kind == RSQUARE) {
                    state = JsonArrayEnd
                } else {
                    state = ExpectJsonValue
                }
            case JsonArrayEnd => isParsing = false
            case _ => throw Exception("Unexpected JsonParserState")
        }
    }
    currPos = conformNext(input, currPos, RSQUARE)
    let tks = match (list |> reduce {acc, i => acc + Token(COMMA) + Token(NL) + i}) {
        case Some(v) =>
            let elems = Token(NL) + v + Token(NL)
            quote(JsonArray([$elems]))
        case None => quote(JsonArray())
    }
    (tks, currPos)
}

func parseObject(input: Tokens, pos: Int64): (Tokens, Int64) {
    var currPos = pos
    var state = JsonParserState.Init
    var isParsing = true
    let list = ArrayList<Tokens>()
    while (currPos < input.size && isParsing) {
        match (state) {
            case Init =>
                currPos = conformNext(input, currPos, LCURL)
                state = JsonObjectStart
            case JsonObjectStart => if (input[currPos].kind == RCURL) {
                state = JsonObjectEnd
            } else {
                state = ExpectKeyValuePair
            }
            case ExpectKeyValuePair =>
                let (key, value): (Tokens, Tokens)
                ((key, value), currPos) = parseKeyValuePair(input, currPos)
                list.append(quote(($key,$value)))
                if (input[currPos].kind == RCURL) {
                    state = JsonObjectEnd
                } else {
                    state = ExpectComma
                }
            case ExpectComma =>
                currPos = skipComma(input, currPos)
                if (input[currPos].kind == RCURL) {
                    state = JsonObjectEnd
                } else {
                    state = ExpectKeyValuePair
                }
            case JsonObjectEnd => isParsing = false
            case _ => throw Exception("Unexpected JsonParserState")
        }
    }
    currPos = conformNext(input, currPos, RCURL)
    let tks = match (list |> reduce {acc, i => acc + Token(COMMA) + Token(NL) + i}) {
        case Some(v) =>
            let pairs = Token(NL) + v + Token(NL)
            quote(JsonObject(HashMap<String, JsonValue>([$pairs])))
        case None => quote(JsonObject())
    }
    (tks, currPos)
}

func skipWhiteSpace(input: Tokens, pos: Int64): Int64 {
    var currPos = pos
    while (currPos < input.size && input[currPos].kind == NL) {
        currPos++
    }
    currPos
}

func skipComma(input: Tokens, pos: Int64): Int64 {
    if (input[pos].kind != COMMA) {
        diagReport(DiagReportLevel.ERROR, input[pos..(pos + 1)], 'Expected ",", found ${input[pos].value}',
            'Failed to parse "${input[pos].value}"')
        throw ASTException('Failed to parse "${input[pos].value}"')
    }
    skipWhiteSpace(input, pos + 1)
}

func parseKeyValuePair(input: Tokens, pos: Int64): ((key: Tokens, value: Tokens), Int64) {
    var currPos = pos
    let key = match (peekExprBeforeColon(input, pos)) {
        case Some((expr, index)) =>
            currPos = index
            expr
        case None where input[currPos].kind == STRING_LITERAL =>
            currPos++
            input[pos].toTokens()
        case None where input[currPos].kind == IDENTIFIER && input[currPos].value != "null" =>
            currPos++
            input[pos].toTokens()
        case _ =>
            diagReport(DiagReportLevel.ERROR, input[currPos..(currPos + 1)],
                'Excepted String literal or String expression, found ${input[currPos].value}',
                'Failed to parse "${input[currPos].value}"')
            throw ASTException('Failed to parse "${input[currPos].value}"')
    }
    currPos = skipWhiteSpace(input, currPos)
    if (input[currPos].kind != COLON) {
        diagReport(DiagReportLevel.ERROR, input[currPos..(currPos + 1)], 'Excepted ":", found ${input[currPos].value}',
            'Failed to parse "${input[currPos].value}"')
        throw ASTException('Failed to parse "${input[currPos].value}"')
    }
    currPos = skipWhiteSpace(input, currPos + 1)
    let value: Tokens
    (value, currPos) = parseValue(input, currPos)
    ((key, value), currPos)
}

func peekExprFragment(input: Tokens, pos: Int64): Option<(Tokens, Int64)> {
    try {
        let (expr, currPos) = parseExprFragment(input, startFrom: pos)
        (expr.toTokens(), currPos)
    } catch (e: ParseASTException) {
        return None
    }
}

func peekExprBeforeColon(input: Tokens, pos: Int64): Option<(Tokens, Int64)> {
    var p = pos
    while (p < input.size && input[p].kind != COLON) {
        p++
    }
    if (p == pos) {
        None
    } else {
        try {
            let tks = parseExpr(input[pos..p]).toTokens()
            (tks, p)
        } catch (e: ParseASTException) {
            None
        }
    }
}

func conformNext(input: Tokens, pos: Int64, kind: TokenKind): Int64 {
    if (input[pos].kind != kind) {
        diagReport(DiagReportLevel.ERROR, input[pos..(pos + 1)],
            'Excepted "${Token(kind).toTokens()}", found ${input[pos].value}', 'Failed to parse "${input[pos].value}"')
        throw ASTException('Failed to parse "${input[pos].value}"')
    }
    skipWhiteSpace(input, pos + 1)
}
