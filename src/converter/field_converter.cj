package juson.converter

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
    for (attr in parseFieldAttrs(attrs)) {
        processField(attr) |> attrStrs.append
    }
    setItem("variable-name", varDecl.identifier.value)
    setItem("variable-attrs", String.join(attrStrs.toArray(), delimiter:","))
    input
}

// 确保属性是逗号分隔的赋值表达式，如 name="aaa", constructor=2
func parseFieldAttrs(attrs: Tokens): Array<AssignExpr> {
    let exprs = ArrayList<AssignExpr>()
    var index = 0
    while(true) {
        let (expr, nextIndex) = parseExprFragment(attrs, startFrom: index)
        match (expr) {
            case a: AssignExpr where a.leftExpr.toTokens().size == 1 && a.rightExpr.toTokens().size == 1 => 
                exprs.append(a)
            case e => 
                diagReport(DiagReportLevel.ERROR, attrs[index..nextIndex], "Invalid attribute",
                    "Invalid attribute")
                throw ASTException("Invalid attribute")
        }
        
        if (nextIndex >= attrs.size)  {
            break
        }
        if (attrs[nextIndex].kind != TokenKind.COMMA) {
            diagReport(DiagReportLevel.ERROR, attrs[nextIndex..nextIndex+1],
                       "Expected comma, found ${attrs[nextIndex].value}",
                       "Input must be a comma-separated list of assign expressions")
            throw ASTException("Input must be a comma-separated list of expressions")
        }
        if (nextIndex == attrs.size-1) {
            diagReport(DiagReportLevel.ERROR, attrs[nextIndex..nextIndex+1],
                       "Expected expression after comma",
                       "Input does not allow trailing comma")
            throw ASTException("Input does not allow trailing comma")
        }
        index = nextIndex + 1
    }
    exprs.toArray()
}

// 每个属性的处理函数，新增属性时需要在这里添加处理逻辑
func processField(attr: AssignExpr): String {
    let name = attr.leftExpr.toTokens()[0].value
    match (name) {
        case "name" => match (attr.rightExpr) {
            case l: LitConstExpr where l.literal.kind == STRING_LITERAL => 
                setItem("name", l.literal.value)
                "name"
            case _ => 
                let value = attr.rightExpr.toTokens()[0].value
                diagReport(DiagReportLevel.ERROR, attr.rightExpr.toTokens(), "Invalid attribute value ${value}",
                "Invalid attribute value")
                throw ASTException("Invalid attribute value")
        }
        case _ => diagReport(DiagReportLevel.ERROR, attr.leftExpr.toTokens(), "Invalid attribute name ${name}",
            "Invalid attribute name ${name}")
            throw ASTException("Invalid attribute name ${name}")
    }
}

