internal package juson.converter.helper

import std.ast.*
import std.collection.{HashMap, map, filter, any, reduce, collectHashSet, collectArray}

public func isOptionType(varDecl: VarDecl): Bool {
    match (varDecl.declType) {
        case p: PrefixType where p.prefixOps.size == 1 && p.prefixOps[0].kind == QUEST => true
        case r: RefType where r.identifier.value == "Option" => true
        case _ => false
    }
}

// 全参数构造函数，Option类型的成员变量默认值为None
public func allNamedArgCtor(varDecls: Array<VarDecl>, attrs: HashMap<String, HashMap<String, Tokens>>): FuncDecl {
    let _ = attrs // unused
    let optionVarNames = varDecls |>
        filter { i => isOptionType(i) } |> map {i => i.identifier.value} |> collectHashSet

    let paramsOpt = varDecls |> 
        map {
        i => if (optionVarNames.contains(i.identifier.value)) {
            quote($(i.identifier)!: $(i.declType) = None)
        } else {
            quote($(i.identifier)!: $(i.declType))
        }
    } |> reduce {acc, i => acc + Token(COMMA) + i}

    let assignsOpt = varDecls |>
        map {i => quote(this.$(i.identifier) = $(i.identifier))} |> reduce {acc, i => acc + Token(NL) + i}

    FuncDecl(
        quote(
        public init($(paramsOpt ?? Tokens())){
            $(assignsOpt ?? Tokens())
        }
    ))
}
