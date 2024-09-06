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

protected class JsonParser {
    private let input: Tokens
    private var pos: Int64 = 0

    public init(input: Tokens) {
        this.input = input
    }

    public prop peek: Token {
        get() {
            input[this.pos]
        }
    }

    public prop next: Token {
        get() {
            this.pos++
            input[this.pos - 1]
        }
    }

    public prop last: Token {
        get() {
            input[this.lastPos]
        }
    }

    public prop lastPos: Int64 {
        get() {
            if (pos <= 0) {
                0
            } else {
                this.pos - 1
            }
        }
    }

    public func skipWhiteSpace(input: Tokens, pos: Int64): Int64 {
        var res = pos
        while (res < this.input.size && input[res].kind == NL) {
            res++
        }
        res
    }

    public func parseWhole(input: Tokens): Tokens{
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
    public func parseValue(input: Tokens, pos: Int64): (Tokens, Int64) {
        var currPos = pos
        match (peekExprFragment(input, currPos)) {
            // 特殊规则：遇到 [ 统一视为jsonArray，因为语法与Array字面量冲突。在宏中请用Array<T>()
            case Some((expr, index)) where input[currPos].kind == LSQUARE => parseJsonValue(input, currPos)
            // 长度>=2的表达式一定不是纯json值
            case Some((expr, index)) where index - currPos != 1 =>
                currPos = index
                (quote(($(expr)).toJsonValue()), currPos)
            // 长度==1，且Token类型是 IDENTIFIER(非null) / this 的表达式一定不是纯json值
            case Some((expr, index)) => match (expr.toTokens()[0].kind) {
                case THIS =>
                    currPos = index
                    (quote(($(expr)).toJsonValue()), currPos)
                case IDENTIFIER where input[currPos].value != "null" =>
                    currPos = index
                    (quote(($(expr)).toJsonValue()), currPos)
                case _ => parseJsonValue(input, currPos)
            }
            case _ => parseJsonValue(input, currPos)
        }
    }

    public func parseJsonValue(input: Tokens, pos: Int64): (Tokens, Int64) {
        var currPos = pos
        currPos = skipWhiteSpace(input, currPos + 1)
        match (input[pos].kind) {
            case STRING_LITERAL => (quote(JsonString($(input[pos]))), currPos)
            case INTEGER_LITERAL => (quote(JsonInt($(input[pos]))), currPos)
            case FLOAT_LITERAL => (quote(JsonFloat($(input[pos]))), currPos)
            case IDENTIFIER where input[pos].value == "null" => (quote(JsonNull()), currPos)
            case BOOL_LITERAL => (quote(JsonBool($(input[pos]))), currPos)
            case LSQUARE =>
                parseArray(input, pos)
            case LCURL =>
                this.parseObject(input, pos)
            case _ =>
                diagReport(DiagReportLevel.ERROR, input[pos..(pos + 1)],
                    'Expected json value, found "${input[pos].value}"', 'Failed to parse "${input[pos].value}"')
                throw ASTException('Failed to parse "${input[pos].value}"')
        }
    }

    public func parseArray(input: Tokens, pos: Int64): (Tokens, Int64) {
        var currPos = pos
        var state = JsonParserState.Init
        var isParsing = true
        let list = ArrayList<Tokens>()
        while (currPos < input.size && isParsing) {
            match (state) {
                case Init =>
                    currPos = conformNext(input, currPos, LSQUARE)
                    state = JsonArrayStart
                case JsonArrayStart =>
                    if (input[currPos].kind == RSQUARE) {
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
                    if (this.peek.kind == RSQUARE) {
                        state = JsonArrayEnd
                    } else {
                        state = ExpectJsonValue
                    }
                case JsonArrayEnd => isParsing = false
                case _ => throw Exception("Unexpected JsonParserState")
            }
        }
        currPos = conformNext(input, currPos, RSQUARE)
        match (list |> reduce {acc, i => acc + Token(COMMA) + Token(NL) + i}) {
            case Some(v) =>
                let elems = Token(NL) + v + Token(NL)
                quote(JsonArray([$elems]))
            case None => quote(JsonArray())
        }
    }

    public func parseObject(input: Tokens, pos: Int64): (Tokens, Int64) {
        var state = JsonParserState.Init
        var isParsing = true
        let list = ArrayList<Tokens>()
        while (this.pos < this.input.size && isParsing) {
            match (state) {
                case Init =>
                    this.skipWhiteSpace()
                    conformNext(LCURL)
                    state = JsonObjectStart
                case JsonObjectStart =>
                    this.skipWhiteSpace()
                    if (this.peek.kind == RCURL) {
                        state = JsonObjectEnd
                    } else {
                        state = ExpectKeyValuePair
                    }
                case ExpectKeyValuePair =>
                    this.skipWhiteSpace()
                    let (key, value) = this.parseKeyValuePair()
                    list.append(quote(($key,$value)))
                    this.skipWhiteSpace()
                    if (this.peek.kind == RCURL) {
                        state = JsonObjectEnd
                    } else {
                        state = ExpectComma
                    }
                case ExpectComma =>
                    this.skipWhiteSpace()
                    this.skipComma()
                    this.skipWhiteSpace()
                    if (this.peek.kind == RCURL) {
                        state = JsonObjectEnd
                    } else {
                        state = ExpectKeyValuePair
                    }
                case JsonObjectEnd => isParsing = false
                case _ => throw Exception("Unexpected JsonParserState")
            }
        }
        conformNext(RCURL)
        match (list |> reduce {acc, i => acc + Token(COMMA) + Token(NL) + i}) {
            case Some(v) =>
                let pairs = Token(NL) + v + Token(NL)
                quote(JsonObject(HashMap<String, JsonValue>([$pairs])))
            case None => quote(JsonObject())
        }
    }

    public func skipComma(input: Tokens, pos: Int64): Int64 {
        if (input[pos].kind != COMMA) {
            diagReport(DiagReportLevel.ERROR, input[pos..(pos + 1)],
                'Expected ",", found ${input[pos].value}', 'Failed to parse "${input[pos].value}"')
            throw ASTException('Failed to parse "${input[pos].value}"')
        }
        skipWhiteSpace(input, pos + 1)
    }

    public func parseKeyValuePair(input: Tokens, pos: Int64): ((key: Tokens, value: Tokens), Int64) {
        // key
        let key = match (this.peekExprBeforeColon()) {
            case Some((expr, index)) =>
                this.pos = index
                expr
            case None where this.peek.kind == STRING_LITERAL => this.next.toTokens()
            case None where this.peek.kind == IDENTIFIER && this.peek.value != "null" => this.next.toTokens()
            case _ =>
                diagReport(DiagReportLevel.ERROR, input[this.pos..(this.pos + 1)],
                    'Excepted String literal or String expression, found ${this.peek.value}',
                    'Failed to parse "${this.peek.value}"')
                throw ASTException('Failed to parse "${this.peek.value}"')
        }
        this.skipWhiteSpace()
        // :
        if (this.next.kind != COLON) {
            diagReport(DiagReportLevel.ERROR, input[this.lastPos..(this.lastPos + 1)],
                'Excepted ":", found ${this.last.value}', 'Failed to parse "${this.last.value}"')
            throw ASTException('Failed to parse "${this.last.value}"')
        }
        this.skipWhiteSpace()
        // value
        (key, parseValue())
    }

    // 注意：parseExprFragment会顺便解析结尾的换行符，要去掉
    public func peekExprFragment(input: Tokens, pos: Int64): Option<(Tokens, Int64)> {
        try {
            var index: Int64 = 0
            (_, index) = parseExprFragment(this.input, startFrom: this.pos)
            index -= 1
            for (_ in 0..this.input.size) {
                if (this.input[index].kind == NL) {
                    index -= 1
                } else {
                    break
                }
            }
            index++
            (this.input[this.pos..index], index)
        } catch (e: ParseASTException) {
            None
        }
    }

    // 也要去掉换行符
    // 专用来解析object中key的表达式，因为正常的parseExprFragment遇到 : 会报错。。。。
    public func peekExprBeforeColon(input: Tokens, pos: Int64): Option<(Tokens, Int64)> {
        var p = this.pos
        while (p < this.input.size && this.input[p].kind != COLON) {
            p++
        }
        try {
            (parseExpr(this.input[this.pos..p]).toTokens(), p)
        } catch (e: ParseASTException) {
            None
        }
    }

    public func conformNext(input: Tokens, pos: Int64, kind: TokenKind): Int64 {
        if (input[pos].kind != kind) {
            diagReport(DiagReportLevel.ERROR, input[pos..(pos + 1)],
                'Excepted "${Token(kind).toTokens()}", found ${input[pos].value}', 'Failed to parse "${input[pos].value}"'
            )
            throw ASTException('Failed to parse "${input[pos].value}"')
        }
        skipWhiteSpace(input, pos + 1)
    }
}
