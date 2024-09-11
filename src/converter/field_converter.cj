protected package juson.converter

import juson.converter.helper.parseCommaSeparatedAttrs

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
    } catch (_: ParseASTException) {
        diagReport(DiagReportLevel.ERROR, input, "Expected a variable declaration, found unsupported syntax",
            "Unsupported syntax")
        throw ASTException("Unsupported syntax")
    }
    // 解析属性
    let attrStrs = ArrayList<String>()
    for (attr in parseCommaSeparatedAttrs(attrs)) {
        processField(attr)
        attrStrs.append(attr.leftExpr.toTokens()[0].value)
    }
    setItem("variable-name", varDecl.identifier.value)
    setItem("variable-attrs", String.join(attrStrs.toArray(), delimiter: ","))
    input
}

// 每个属性的处理函数，新增属性时需要在这里添加处理逻辑
func processField(attr: AssignExpr): Unit {
    let name = attr.leftExpr.toTokens()[0].value
    // 处理属性
    if (name == "name") {
        match (attr.rightExpr) {
            case l: LitConstExpr where l.literal.kind == STRING_LITERAL => setItem("name", l.toTokens())
            case _ => 
                diagReport(DiagReportLevel.ERROR, attr.rightExpr.toTokens(),
                    'Expect a string literal, found \"${attr.rightExpr.toTokens()}\"',
                    "Invalid attribute value \"${attr.rightExpr.toTokens()}\"")
                throw ASTException("Invalid attribute value \"${attr.rightExpr.toTokens()}\"")
        }
    } else if (name == "required") {
        match (attr.rightExpr) {
            case l: LitConstExpr where l.literal.kind == BOOL_LITERAL => setItem("required", l.toTokens())
            case _ => 
                diagReport(DiagReportLevel.ERROR, attr.rightExpr.toTokens(),
                    'Expect "true" or "false", found \"${attr.rightExpr.toTokens()}\"',
                    "Invalid attribute value \"${attr.rightExpr.toTokens()}\"")
                throw ASTException("Invalid attribute value \"${attr.rightExpr.toTokens()}\"")
        }
    } else if (name == "default") {
        setItem("default", attr.rightExpr.toTokens())
    } else if (name == "skip") {
        match (attr.rightExpr) {
            case r: RefExpr where r.identifier.value == "all" || r.identifier.value == "serializing" ||
                r.identifier.value == "deserializing" => setItem("skip", r.toTokens())
            case _ =>
                diagReport(DiagReportLevel.ERROR, attr.rightExpr.toTokens(),
                    'Expect "all", "serializing" or "deserializing", found "${attr.rightExpr.toTokens()}"',
                    "Invalid attribute value \"${attr.rightExpr.toTokens()}\"") 
                throw ASTException("Invalid attribute value \"${attr.rightExpr.toTokens()}\"")
        }
    } else {
        diagReport(DiagReportLevel.ERROR, attr.leftExpr.toTokens(), "Invalid attribute name \"${name}\"",
            "Invalid attribute name \"${name}\"")
        throw ASTException("Invalid attribute name \"${name}\"")
    }
}
