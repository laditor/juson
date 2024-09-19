protected package juson.converter

import juson.converter.helper.{parseCommaSeparatedAttrs, unwrapType, compareType}

protected func fieldConvertor(attrs: Tokens, input: Tokens): Tokens {
    // 检查，必须是变量声明
    assertParentContext("Juson")
    let varDecl: VarDecl
    try {
        match (parseDecl(input)) {
            case v: VarDecl => varDecl = v
            case d: Decl =>
                diagReport(DiagReportLevel.ERROR, input, "Expected a variable declaration, found ${d.keyword.value}",
                    "Unsupported declaration")
                throw ASTException("Unexpected declaration")
        }
        let _ = varDecl.declType // 确保有类型声明
    } catch (_: ParseASTException) {
        diagReport(DiagReportLevel.ERROR, input, "Expected a variable declaration, found unsupported syntax",
            "Unsupported syntax")
        throw ASTException("Unsupported syntax")
    } catch (_: ASTException) { // 类型声明缺失
        diagReport(DiagReportLevel.ERROR, input, "VarDecl must have a type declaration",
            "VarDecl must have a type declaration")
        throw ASTException("VarDecl must have a type declaration")
    }
    // 解析属性
    let attrStrs = ArrayList<String>()
    for (attr in parseCommaSeparatedAttrs(attrs)) {
        processField(varDecl, attr)
        attrStrs.append(attr.leftExpr.toTokens()[0].value)
    }
    setItem("variable-name", varDecl.identifier.value)
    setItem("variable-attrs", String.join(attrStrs.toArray(), delimiter: ","))
    input
}

enum State {
    | Serializing
    | Deserializing
}

// 每个属性的处理函数，新增属性时需要在这里添加处理逻辑
func processField(varDecl: VarDecl, attr: AssignExpr): Unit { // cjlint-ignore !G.FUN.01
    let name = attr.leftExpr.toTokens()[0].value
    // 处理属性
    if (name == "name") {
        match (attr.rightExpr) {
            case l: LitConstExpr where l.literal.kind == STRING_LITERAL => setItem("name", l.toTokens())
            case _ => 
                diagReport(DiagReportLevel.ERROR, attr.rightExpr.toTokens(),
                    'Expect a string literal, found "${attr.rightExpr.toTokens()}"',
                    "Invalid attribute value \"${attr.rightExpr.toTokens()}\"")
                throw ASTException("Invalid attribute value \"${attr.rightExpr.toTokens()}\"")
        }
    } else if (name == "default") {
        setItem("default", attr.rightExpr.toTokens())
    } else if (name == "skip") {
        match (attr.rightExpr) {
            case r: RefExpr where r.identifier.value == "all" || r.identifier.value == "serializing" ||
                r.identifier.value == "deserializing" || r.identifier.value == "none" => setItem("skip", r.toTokens())
            case t: TrailingClosureExpr =>
                match (t.expr) {
                    case r: RefExpr where r.identifier.value == "serializing" => 
                        processConditionalLambda(varDecl, t.lambdaExpr, Serializing)
                        setItem("skip", t.toTokens())
                    case r: RefExpr where r.identifier.value == "deserializing" => 
                        processConditionalLambda(varDecl, t.lambdaExpr, Deserializing)
                        setItem("skip", t.toTokens())
                    case _ =>
                        diagReport(DiagReportLevel.ERROR, attr.rightExpr.toTokens(),
                            'Expect "serializing" or "deserializing" with trailing lambda, found "${attr.rightExpr.toTokens()}"',
                            "Invalid attribute value \"${attr.rightExpr.toTokens()}\"")
                        throw ASTException("Invalid attribute value \"${attr.rightExpr.toTokens()}\"")
                }
            case _ =>
                diagReport(DiagReportLevel.ERROR, attr.rightExpr.toTokens(),
                    'Expect "none", "all", "serializing" or "deserializing", found "${attr.rightExpr.toTokens()}"',
                    "Invalid attribute value \"${attr.rightExpr.toTokens()}\"") 
                throw ASTException("Invalid attribute value \"${attr.rightExpr.toTokens()}\"")
        }
    } else if (name == "format") {
        match (attr.rightExpr) {
            case l: LitConstExpr where l.literal.kind == STRING_LITERAL => setItem("format", l.toTokens())
            case _ => 
                diagReport(DiagReportLevel.ERROR, attr.rightExpr.toTokens(),
                    'Expect a string literal, found "${attr.rightExpr.toTokens()}"',
                    "Invalid attribute value \"${attr.rightExpr.toTokens()}\"")
                throw ASTException("Invalid attribute value \"${attr.rightExpr.toTokens()}\"")
        }
    } else if (name == "serialize") {
        match (attr.rightExpr) {
            case r: RefExpr => setItem("serialize", r.toTokens())
            case _ => 
                diagReport(DiagReportLevel.ERROR, attr.rightExpr.toTokens(),
                    'Expect a function reference, found "${attr.rightExpr.toTokens()}"',
                    "Invalid attribute value \"${attr.rightExpr.toTokens()}\"")
                throw ASTException("Invalid attribute value \"${attr.rightExpr.toTokens()}\"")
        }
    } else if (name == "deserialize") {
        match (attr.rightExpr) {
            case r: RefExpr => setItem("deserialize", r.toTokens())
            case _ => 
                diagReport(DiagReportLevel.ERROR, attr.rightExpr.toTokens(),
                    'Expect a function reference, found "${attr.rightExpr.toTokens()}"',
                    "Invalid attribute value \"${attr.rightExpr.toTokens()}\"")
                throw ASTException("Invalid attribute value \"${attr.rightExpr.toTokens()}\"")
        }
    } else {
        diagReport(DiagReportLevel.ERROR, attr.leftExpr.toTokens(), "Invalid attribute name \"${name}\"",
            "Invalid attribute name \"${name}\"")
        throw ASTException("Invalid attribute name \"${name}\"")
    }
}

func processConditionalLambda(varDecl: VarDecl, lambda: LambdaExpr, state: State): Unit {
    match (state) {
        case Serializing =>
            if (lambda.funcParams.size != 1) {
                diagReport(DiagReportLevel.ERROR, lambda.toTokens(),
                    "Expect a lambda with one ${varDecl.declType.toTokens()} parameter, found ${lambda.funcParams.size} parameters",
                    "Invalid lambda parameters")
                throw ASTException("Invalid lambda parameters")
            }
            if (lambda.funcParams[0].paramType.toTokens().size != 0 && !compareType(varDecl.declType, lambda.funcParams[0].paramType)) {
                diagReport(DiagReportLevel.ERROR, lambda.toTokens(),
                    "Expect a lambda with one ${varDecl.declType.toTokens()} parameter, found ${lambda.funcParams[0].paramType.toTokens()}",
                    "Invalid lambda parameter type")
                throw ASTException("Invalid lambda parameter type")
            }
            lambda.funcParams[0].paramType = varDecl.declType
        case Deserializing => 
            if (lambda.funcParams.size != 1) {
                diagReport(DiagReportLevel.ERROR, lambda.toTokens(),
                    "Expect a lambda with no parameter, found ${lambda.funcParams.size} parameters",
                    "Invalid lambda parameters")
                throw ASTException("Invalid lambda parameters")
            }
            if (lambda.funcParams[0].paramType.toTokens().size != 0 && !compareType(lambda.funcParams[0].paramType, RefType(quote(JsonValue)))) {
                diagReport(DiagReportLevel.ERROR, lambda.toTokens(),
                    "Expect a lambda with one JsonValue parameter, found ${lambda.funcParams[0].paramType.toTokens()}",
                    "Invalid lambda parameter type")
                throw ASTException("Invalid lambda parameter type")
            }
            lambda.funcParams[0].paramType = RefType(quote(JsonValue))
    }
}
