internal package juson.converter.helper

import std.ast.*

public func compareType(type1: TypeNode, type2: TypeNode): Bool {
    compareTokens(unwrapType(type1).toTokens(), unwrapType(type2).toTokens())
}

public func unwrapType(varDecl: VarDecl): TypeNode { unwrapType(varDecl.declType) }

public func unwrapType(typeNode: TypeNode): TypeNode {
    match (typeNode) {
        case p: ParenType => unwrapType(p.parenthesizedType)
        case q: QualifiedType => unwrapType(parseType(q.identifier.toTokens()))
        case _ => typeNode
    }
}

// 判断是否是Option类型
public func isOptionType(varDecl: VarDecl): Bool {
    match (varDecl.declType) {
        case p: PrefixType where p.prefixOps.size == 1 && p.prefixOps[0].kind == QUEST => true
        case r: RefType where r.identifier.value == "Option" => true
        case _ => false
    }
}