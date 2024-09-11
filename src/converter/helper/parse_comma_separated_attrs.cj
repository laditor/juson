internal package juson.converter.helper

import std.ast.*
import std.collection.{ArrayList}

// 确保属性是逗号分隔的赋值表达式，如 name="aaa", constructor=2
public func parseCommaSeparatedAttrs(attrs: Tokens): Array<AssignExpr> {
    let exprs = ArrayList<AssignExpr>()
    var index = 0
    while (true) {
        try {
            let (expr, nextIndex) = parseExprFragment(attrs, startFrom: index) // throws ParseASTException
            match (expr) {
                case a: AssignExpr where a.leftExpr.toTokens().size == 1 => exprs.append(
                    a)
                case e =>
                    diagReport(DiagReportLevel.ERROR, attrs[index..nextIndex], 'Expected "attr = value", found \"${e.toTokens()}\"',
                        "Invalid attribute")
                    throw ASTException("Invalid attribute")
            }

            if (nextIndex >= attrs.size) {
                break
            }
            if (attrs[nextIndex].kind != TokenKind.COMMA) {
                diagReport(DiagReportLevel.ERROR, attrs[nextIndex..nextIndex + 1],
                    "Expected \",\", found \"${attrs[nextIndex].value}\"",
                    "Input must be a comma-separated list of assign expressions")
                throw ASTException("Input must be a comma-separated list of expressions")
            }
            if (nextIndex == attrs.size - 1) {
                diagReport(DiagReportLevel.ERROR, attrs[nextIndex..nextIndex + 1], "Expected expression after \",\"",
                    "Input does not allow trailing comma")
                throw ASTException("Input does not allow trailing comma")
            }
            index = nextIndex + 1
        } catch (_: ParseASTException) {
            diagReport(DiagReportLevel.ERROR, attrs[index..], 'Expected "attr = value", found \"${attrs[index..]}\"',
                "Invalid attribute")
            throw ASTException("Invalid attribute")
        }
    }
    exprs.toArray()
}