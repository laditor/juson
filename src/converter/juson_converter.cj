package juson.converter

protected enum JsonSerializableFunc {
    | JusonSerialize
    | JusonDeserialize
}

protected func jusonConverter(input: Tokens): Tokens {
    try {
        match (parseDecl(input)) {
            case v: ClassDecl => jusonClass(v)
            case v: StructDecl => jusonStruct(v)
            case anyone =>
                diagReport(DiagReportLevel.ERROR, input, "Expected class or struct, found ${anyone.keyword.value}",
                    "Unsupported type ${anyone.keyword.value}")
                throw ASTException("Unsupported ${anyone.keyword.value} type")
        }
    } catch (_: ParseASTException) {
        diagReport(DiagReportLevel.ERROR, input, "Expected class or struct, found unsupported type", "Unsupported type")
        throw ASTException("Unsupported type")
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
    let (varDecls, varAttrMap, hasFuncs) = collectVarAttrsHasFuncs(body)
    // serialize
    if (!hasFuncs[0]) {
        let pairArray = match (varDecls |> map {
            v => jusonSerializeField(v, varAttrMap.get(v.identifier.value))
        } |> filter {i => i.size > 0} |> reduce {
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
            v => jusonDeserializeField(v, varAttrMap.get(v.identifier.value))
        } |> filter {i => i.size > 0} |> reduce {
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

// jusonSerialize中字段的序列化Tokens
func jusonSerializeField(varDecl: VarDecl, attrs: ?HashMap<String, String>): Tokens {
    let map = match (attrs) {
        case Some(a) => a
        case None => return quote (($(varDecl.identifier.value), $(varDecl.identifier).jusonSerialize()))
    }
    // 处理skip属性
    if (map.get("skip") == "all" || map.get("skip") == "serializing") {
        return quote()
    }

    // 处理name属性
    let varName = map.get("name") ?? varDecl.identifier.value
    quote (($(varName), $(varDecl.identifier).jusonSerialize()))
}

// jusonSerialize中字段的序列化Tokens
func jusonDeserializeField(varDecl: VarDecl, attrs: ?HashMap<String, String>): Tokens {
    let map = match (attrs) {
        case Some(a) =>
            handleDeserAttrConfliction(varDecl, a)
            a
        case None => return quote (
            result.$(varDecl.identifier) = $(varDecl.declType).jusonDeserialize(jsonObject[$(varDecl.identifier.value)]))
    }
    // 处理skip属性
    if (map.get("skip") == "all" || map.get("skip") == "deserializing") {
        return quote()
    }

    // 处理name属性
    let varName = map.get("name") ?? varDecl.identifier.value

    // 处理required和default属性
    let result = quote (result.$(varDecl.identifier) = $(varDecl.declType).jusonDeserialize(jsonObject[$(varName)]))
    if (map.get("required") == "true") {
        let exceptionStr = Token(STRING_LITERAL, "Excepted required field \"${varName}\" , not found in json")
        quote (
            if (jsonObject.containsKey($(varName))) { $result } 
            else { throw IllegalArgumentException($(exceptionStr)) }
        )
    } else if (map.contains("default")) {
        let defaultValue = cangjieLex(map["default"], true)
        quote (
            if (jsonObject.containsKey($(varName))) { $result} 
            else { result.$(varDecl.identifier) = $defaultValue }
        )
    } else {
        quote (
            if (jsonObject.containsKey($(varName))) { $result }
        )
    }
}

func handleDeserAttrConfliction(varDecl: VarDecl, attrs: HashMap<String, String>): Unit {
    let _ = varDecl
    let conflict = {
        kv1: String, kv2: String =>
        diagReport(DiagReportLevel.ERROR, varDecl.toTokens(), "Conflicting attributes: \"${kv1}\" and \"${kv2}\"",
            "Conflicting attributes: \"${kv1}\" and \"${kv2}\"")
        throw ASTException("Conflicting attributes: \"${kv1}\" and \"${kv2}\"")
    }
    if (attrs.get("required") == "true" && attrs.get("skip") == "all") { // required和skip=all冲突
        conflict("required=true", "skip=all")
    }
    if (attrs.get("required") == "true" && attrs.get("skip") == "deserializing") { // required和skip=deserializing冲突
        conflict("required=true", "skip=deserializing")
    }
    if (attrs.get("required") == "true" && attrs.contains("default")) { // required和default冲突
        conflict("required=true", "default")
    }
}

// hasFuncs: 0-serialize, 1-deserialize
func collectVarAttrsHasFuncs(body: Body): (Array<VarDecl>, HashMap<String, HashMap<String, String>>, Array<Bool>) {
    let varDecls = ArrayList<VarDecl>() // 收集var变量
    let hasFuncs = Array<Bool>(2, item: false) //判断是否已存在相关函数，[0]-serialize, [1]-deserialize
    let varAttrMap = HashMap<String, HashMap<String, String>>() // 收集var的属性
    var declT: Decl = VarDecl() // 记录声明用于报错

    // 获取Field宏发送的信息
    let messages: ArrayList<MacroMessage> = getChildMessages("Field")
    // 收集变量属性到varAttrMap
    for (msg in messages) {
        let varName = msg.getString("variable-name")
        let varAttrs = msg.getString("variable-attrs").split(",")
        let attrMap = HashMap<String, String>()
        for (a in varAttrs) {
            attrMap.put(a, msg.getString(a))
        }
        varAttrMap.put(varName, attrMap)
    }
    try {
        for (decl in body.decls) {
            declT = decl
            match (decl) {
                case v: VarDecl =>
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
    (varDecls.toArray(), varAttrMap, hasFuncs)
}

// 判断函数是否是Juson序列化/反序列化函数
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
