internal package juson.converter.helper

import std.ast.*
import std.collection.{HashMap, map, filter, any, reduce, collectHashSet, collectArray}

// 全参数构造函数
public func allNamedArgCtor(varDecls: Array<VarDecl>, attrs: HashMap<String, HashMap<String, Tokens>>): FuncDecl {
    let excludedVarNames = attrs |> 
        filter { kv: (String, HashMap<String, Tokens>) =>
            kv[1].get("skip")?[0].value == "all" || kv[1].get("skip")?[0].value == "deserializing"
        } |> map {kv => kv[0]} |> collectHashSet
    let paramsOpt = varDecls |> filter {i => !excludedVarNames.contains(i.identifier.value)} |>
        map {i => quote($(i.identifier)!: $(i.declType))} |>
        reduce {acc, i => acc + Token(COMMA) + i}
    let assignsOpt = varDecls |> filter {i => !excludedVarNames.contains(i.identifier.value)} |>
        map {i => quote(this.$(i.identifier) = $(i.identifier))} |> 
        reduce {acc, i => acc + Token(NL) + i}
    FuncDecl(quote(
        public init($(paramsOpt ?? Tokens())){
            $(assignsOpt ?? Tokens())
        }
    ))
}
