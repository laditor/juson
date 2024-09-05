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

    public func skipWhiteSpace(): Unit {
        while (this.pos < this.input.size && this.peek.kind == NL) {
            this.pos++
        }
    }

    public func parseWhole(): Tokens {
        let result = this.parseValue()
        this.skipWhiteSpace()
        if (this.pos != this.input.size) {
            diagReport(DiagReportLevel.ERROR, input[this.pos..], 'Excepted no more data here',
                'Unexpected trailing data after JSON value')
            throw ASTException('Unexpected trailing data after JSON value')
        }
        result
    }

    public func parseValue(): Tokens {
        this.skipWhiteSpace()
        match (this.peekExprFragment()) {
            // 长度>=2的表达式一定不是纯json值
            case Some((expr, index)) where index - this.pos != 1 =>
                this.pos = index
                quote(($(expr)).toJsonValue())
            // 长度==1，且Token类型是IDENTIFIER(非null)的表达式一定不是纯json值
            case Some((expr, index)) => match (expr.toTokens()[0].kind) {
                case THISTYPE | THIS =>
                    this.pos = index
                    quote(($(expr)).toJsonValue())
                case IDENTIFIER where this.peek.value != "null" =>
                    this.pos = index
                    quote(($(expr)).toJsonValue())
                case _ => this.parseJsonValue()
            }
            case _ => this.parseJsonValue()
        }
    }

    public func parseJsonValue(): Tokens {
        let single = this.next
        match (single.kind) {
            case STRING_LITERAL => quote(JsonString($single))
            case INTEGER_LITERAL => quote(JsonInt($single))
            case FLOAT_LITERAL => quote(JsonFloat($single))
            case IDENTIFIER where single.value == "null" => quote(JsonNull())
            case BOOL_LITERAL => quote(JsonBool($single))
            case LSQUARE =>
                this.pos--
                this.parseArray()
            case LCURL =>
                this.pos--
                this.parseObject()
            case _ =>
                diagReport(DiagReportLevel.ERROR, input[this.lastPos..(this.lastPos + 1)],
                    'Failed to parse Json Value "${single.value}"', "Illegal value")
                throw ASTException('Failed to parse "${single.value}"')
        }
    }

    public func parseArray(): Tokens {
        var state = JsonParserState.Init
        var isParsing = true
        let list = ArrayList<Tokens>()
        while (this.pos < this.input.size && isParsing) {
            match (state) {
                case Init =>
                    this.skipWhiteSpace()
                    conformNext(LSQUARE)
                    state = JsonArrayStart
                case JsonArrayStart =>
                    this.skipWhiteSpace()
                    if (this.peek.kind == RSQUARE) {
                        state = JsonArrayEnd
                    } else {
                        state = ExpectJsonValue
                    }
                case ExpectJsonValue =>
                    this.skipWhiteSpace()
                    list.append(this.parseValue())
                    this.skipWhiteSpace()
                    if (this.peek.kind == RSQUARE) {
                        state = JsonArrayEnd
                    } else {
                        state = ExpectComma
                    }
                case ExpectComma =>
                    this.skipWhiteSpace()
                    this.parseComma()
                    this.skipWhiteSpace()
                    if (this.peek.kind == RSQUARE) {
                        state = JsonArrayEnd
                    } else {
                        state = ExpectJsonValue
                    }
                case JsonArrayEnd => isParsing = false
                case _ => throw Exception("Unexpected JsonParserState")
            }
        }
        conformNext(RSQUARE)
        match (list |> reduce {acc, i => acc + Token(COMMA) + Token(NL) + i}) {
            case Some(v) =>
                let elems = Token(NL) + v + Token(NL)
                quote(JsonArray([$elems]))
            case None => quote(JsonArray())
        }
    }

    public func parseObject(): Tokens {
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
                    this.parseComma()
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

    public func parseComma(): Unit {
        if (this.next.kind != COMMA) {
            diagReport(DiagReportLevel.ERROR, input[this.lastPos..(this.lastPos + 1)],
                'Expected ",", found ${this.last.value}', 'Failed to parse "${this.last.value}"')
            throw ASTException('Failed to parse "${this.last.value}"')
        }
    }

    public func parseKeyValuePair(): (key: Tokens, value: Tokens) {
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
    public func peekExprFragment(): Option<(Tokens, Int64)> {
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
    public func peekExprBeforeColon(): Option<(Tokens, Int64)> {
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

    public func conformNext(kind: TokenKind): Unit {
        if (this.next.kind != kind) {
            diagReport(DiagReportLevel.ERROR, input[this.lastPos..(this.lastPos + 1)],
                'Excepted "${Token(kind).toTokens()}", found ${this.last.value}', 'Failed to parse "${this.last.value}"'
            )
            throw ASTException('Failed to parse "${this.last.value}"')
        }
    }
}
