macro package juson

import std.ast.*
import std.collection.{ArrayList, map, reduce, collectArray}

public macro JsonSerializable(input: Tokens): Tokens {
    jsonSerializable(input)
}

enum JsonSerializableFunc {
    | Serialize
    | Deserialize
}

func jsonSerializable(input: Tokens): Tokens {
    try {
        match (parseDecl(input)) {
            case v: ClassDecl => jsonSerClass(v)
            // case v: StructDecl => jsonserStruct(v)
            case anyone =>
                diagReport(DiagReportLevel.ERROR, input, "Expected class or struct, found ${anyone.keyword.value}",
                    "Unsupported type ${anyone.keyword.value} for @JsonSerializable")
                throw ASTException("Unsupported ${anyone.keyword.value} type for @JsonSerializable")
        }
    } catch (_: ParseASTException) {
        diagReport(DiagReportLevel.ERROR, input, "Expected class or struct, found unsupported type",
            "Unsupported type for @JsonSerializable")
        throw ASTException("Unsupported type for @JsonSerializable")
    }
}

func jsonSerClass(clazz: ClassDecl): Tokens {
    // 添加Serializable<T>接口和ToJson接口
    clazz.superTypes.append(RefType(quote(Serializable<$(clazz.identifier)>)))
    jsonSerBody(clazz.body, clazz.identifier)
    clazz.toTokens()
}

func jsonSerBody(body: Body, clazzId: Token): Unit {
    // 收集var变量，判断是否已存在相关函数
    let varDecls = ArrayList<VarDecl>()
    let hasFuncs = Array<Bool>(2, item: false) // 0-serialize, 1-deserialize, 2-toJson, 3-fromJson
    var declT: Decl = VarDecl()
    try {
        for (decl in body.decls) {
            declT = decl
            match (decl) {
                case v: VarDecl where v.keyword.kind == VAR =>
                    let _ = v.declType // 仅用来保证变量写了类型
                    varDecls.append(v)
                case v: FuncDecl => match (judgeFunc(v)) {
                    case Some(Serialize) => hasFuncs[0] = true
                    case Some(Deserialize) => hasFuncs[1] = true
                    case None => ()
                }
                case _ => (0)
            }
        }
    } catch (_: ASTException) {
        diagReport(DiagReportLevel.ERROR, declT.toTokens(), "Expected explicit type declare", "Type declare not found")
        throw ASTException("Type declare not found")
    }
    // serialize
    if (!hasFuncs[0]) {
        let dotAdds = varDecls |> map {
            v => quote(.add(field<$(v.declType)>($(v.identifier.value), $(v.identifier))))
        } |> collectArray
        body.decls.append(
            FuncDecl(
            quote(
            public func serialize(): DataModel {
                DataModelStruct()$dotAdds
            }
        )
        ))
    }
    // deserialize
    if (!hasFuncs[1]) {
        let desers = varDecls |> map {
            v => quote(result.$(v.identifier) = $(v.declType).deserialize(dms.get($(v.identifier.value))))
        } |> reduce {
            acc, v => acc + Token(NL) + v
        }
        body.decls.append(
            FuncDecl(
            quote(
            public static func deserialize(dm: DataModel): $clazzId {
                let dms = match (dm) {
                    case data: DataModelStruct => data
                    case _ => throw Exception("This data is not DataModelStruct")
                }
                let result = $clazzId()
                $(desers ?? Token())
                return result
            }
        )
        ))
    }
}

func judgeFunc(funcDecl: FuncDecl): Option<JsonSerializableFunc> {
    try {
        // 仅校验函数名称和参数
        // 子类继承接口，子类方法的参数类型必须和接口中保持一致，但是返回类型可以是接口中函数返回类型的子类
        match (funcDecl.identifier.value) {
            case "serialize" => if (funcDecl.funcParams.size == 0) {
                Serialize
            } else {
                None
            }
            case "deserialize" =>
                let paramType = (funcDecl.funcParams[0].paramType as RefType).getOrThrow()
                if (funcDecl.funcParams.size == 1 && paramType.identifier.value == "DataModel") {
                    Deserialize
                } else {
                    None
                }
            case _ => None
        }
    } catch (_: ASTException) {
        None
    }
}
