macro package juson

public macro Juson(input: Tokens): Tokens {
    juson(input)
}

enum JsonSerializableFunc {
    | JusonSerialize
    | JusonDeserialize
}

func juson(input: Tokens): Tokens {
    try {
        match (parseDecl(input)) {
            case v: ClassDecl => jusonClass(v)
            case v: StructDecl => jusonStruct(v)
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

func jusonClass(clazz: ClassDecl): Tokens {
    // 添加JusonSerializable<T>接口
    clazz.superTypes.append(RefType(quote(JusonSerializable)))
    clazz.superTypes.append(RefType(quote(JusonDeserializable<$(clazz.identifier)>)))
    jusonBody(clazz.body, clazz.identifier)
    clazz.toTokens()
}

func jusonStruct(clazz: StructDecl): Tokens {
    // 添加JusonSerializable<T>接口
    clazz.superTypes.append(RefType(quote(JusonSerializable)))
    clazz.superTypes.append(RefType(quote(JusonDeserializable<$(clazz.identifier)>)))
    jusonBody(clazz.body, clazz.identifier)
    clazz.toTokens()
}

func jusonBody(body: Body, clazzId: Token): Unit {
    let (varDecls, hasFuncs) = collectVarsHasFuncs(body)
    // serialize
    if (!hasFuncs[0]) {
        let pairArray = match (varDecls |> map {
            v => quote(($(v.identifier.value), $(v.identifier).jusonSerialize()))
        } |> reduce {
            acc, v => acc + Token(COMMA) + Token(NL) + v
        }) {
            case Some(s) => Token(LSQUARE) + s + Token(RSQUARE)
            case None => quote()
        }
        body.decls.append(
            FuncDecl(
            quote(
            public func jusonSerialize(): JsonObject {
                JsonObject(HashMap<String, JsonValue>($pairArray))
            }
        )
        ))
    }
    // deserialize
    if (!hasFuncs[1]) {
        let desers = match (varDecls |> map {
            v => quote(result.$(v.identifier) = $(v.declType).jusonDeserialize(jsonObject[$(v.identifier.value)]))
        } |> reduce {
            acc, v => acc + Token(NL) + v
        }) {
            case Some(s) => s
            case None => quote()
        }
        body.decls.append(
            FuncDecl(
            quote(
            public static func jusonDeserialize(jsonValue: JsonValue): $clazzId {
                let jsonObject = jsonValue.asObject()
                var result = $clazzId()
                $desers
                return result
            }
        )
        ))
    }
}

// Array<Bool>: 0-serialize, 1-deserialize
func collectVarsHasFuncs(body: Body): (Array<VarDecl>, Array<Bool>) {
    // 收集var变量，判断是否已存在相关函数
    let varDecls = ArrayList<VarDecl>()
    let hasFuncs = Array<Bool>(2, item: false)
    var declT: Decl = VarDecl()
    try {
        for (decl in body.decls) {
            declT = decl
            match (decl) {
                case v: VarDecl where v.keyword.kind == VAR =>
                    let _ = v.declType // 仅用来保证变量写了类型
                    varDecls.append(v)
                case v: FuncDecl => match (judgeFunc(v)) {
                    case Some(JusonSerialize) => hasFuncs[0] = true
                    case Some(JusonDeserialize) => hasFuncs[1] = true
                    case None => ()
                }
                case _ => ()
            }
        }
    } catch (_: ASTException) {
        diagReport(DiagReportLevel.ERROR, declT.toTokens(), "Expected explicit type declare", "Type declare not found")
        throw ASTException("Type declare not found")
    }
    (varDecls.toArray(), hasFuncs)
}

func judgeFunc(funcDecl: FuncDecl): Option<JsonSerializableFunc> {
    try {
        // 仅校验函数名称和参数
        // 子类继承接口，子类方法的参数类型必须和接口中保持一致，但是返回类型可以是接口中函数返回类型的子类
        match (funcDecl.identifier.value) {
            case "serialize" => if (funcDecl.funcParams.size == 0) {
                JusonSerialize
            } else {
                None
            }
            case "deserialize" =>
                let paramType = (funcDecl.funcParams[0].paramType as RefType).getOrThrow()
                if (funcDecl.funcParams.size == 1 && paramType.identifier.value == "DataModel") {
                    JusonDeserialize
                } else {
                    None
                }
            case _ => None
        }
    } catch (_: ASTException) {
        None
    }
}
