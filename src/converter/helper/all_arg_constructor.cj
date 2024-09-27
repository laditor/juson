internal package juson.converter.helper

import std.ast.*
import std.collection.{HashMap, map, filter, any, reduce, collectHashSet, collectArray}

// 全参数构造函数，Option类型的成员变量默认值为None
public func allNamedArgCtor(varDecls: Array<VarDecl>, attrs: HashMap<String, HashMap<String, Tokens>>): FuncDecl {
    let _ = attrs // unused
    let optionVarNames = varDecls |> filter {i => isOptionType(i)} |> map {i => i.identifier.value} |> collectHashSet
    let defaultVarNames = varDecls |> filter {i: VarDecl => attrs.get(i.identifier.value)?.contains("default") == true} |>
        map {i => i.identifier.value} |> collectHashSet
        
    let paramsOpt = varDecls |>
        map {
        i => 
        let eqDefault = if (optionVarNames.contains(i.identifier.value)) {
            quote(= None)
        } else if (defaultVarNames.contains(i.identifier.value)){
            quote(= $(attrs[i.identifier.value]["default"]))
        } else {
            Tokens()
        }
        quote($(i.identifier)!: $(i.declType) $(eqDefault))
    } |> reduce {acc, i => acc + Token(COMMA) + i}

    let assignsOpt = varDecls |> map {i => quote(this.$(i.identifier) = $(i.identifier))} |>
        reduce {acc, i => acc + Token(NL) + i}

    FuncDecl(
        quote(
        public init($(paramsOpt ?? Tokens())){
            $(assignsOpt ?? Tokens())
        }
    ))
}
