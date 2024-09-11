protected package juson.converter

import juson.converter.helper.allNamedArgCtor
import juson.exception.DeserializationException
import encoding.json.JsonInt

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
    checkVarNameConflict(varDecls, varAttrMap)
    // serialize
    if (!hasFuncs[0]) {
        let pairsOpt = varDecls |> map {
            v => jusonSerializeField(v, varAttrMap.get(v.identifier.value))
        } |> filter {i => i.size > 0} |> reduce {
            acc, v => acc + Token(COMMA) + Token(NL) + v
        }
        body.decls.append(
            FuncDecl(
            quote(
            public func jusonSerialize(): JsonObject {
                JsonObject([
                    $(pairsOpt ?? Tokens())
                ] |> collectHashMap<String, JsonValue>)
            }
        )
        ))
    }
    // deserialize
    if (!hasFuncs[1]) {
        let paramsOpt = varDecls |> map {
            v => jusonDeserializeField(v, varAttrMap.get(v.identifier.value))
        } |> filter {i => i.size > 0} |> reduce {
            acc, v => acc + Token(COMMA) + Token(NL) + v
        }
        body.decls.append(
            FuncDecl(
            quote(
            public static func jusonDeserialize(jsonValue: JsonValue): $clazzId {
                match (jsonValue) {
                    case jsonObject: JsonObject =>
                        $(clazzId)(
                            $(paramsOpt ?? Tokens())
                        )
                    case _: JsonInt => throw DeserializationException("Expected JsonObject, found JsonInt")
                    case _: JsonFloat => throw DeserializationException("Expected JsonObject, found JsonFloat")
                    case _: JsonString => throw DeserializationException("Expected JsonObject, found JsonString")
                    case _: JsonBool => throw DeserializationException("Expected JsonObject, found JsonBool")
                    case _: JsonArray => throw DeserializationException("Expected JsonObject, found JsonArray")
                    case _: JsonNull => throw DeserializationException("Expected JsonObject, found JsonNull")
                }
            }
        )
        ))
    }
    // 全参数构造函数
    body.decls.append(allNamedArgCtor(varDecls, varAttrMap))
}

// jusonSerialize中字段的序列化Tokens
func jusonSerializeField(varDecl: VarDecl, attrs: ?HashMap<String, Tokens>): Tokens {
    let map = match (attrs) {
        case Some(a) => a
        case None => return quote(($(varDecl.identifier.value), $(varDecl.identifier).jusonSerialize()))
    }
    // 处理skip属性
    if (map.get("skip")?[0].value == "all" || map.get("skip")?[0].value == "serializing") {
        return quote()
    }

    // 处理name属性
    let varName = map.get("name")?[0].value ?? varDecl.identifier.value
    quote(($(varName), $(varDecl.identifier).jusonSerialize()))
}

// jusonSerialize中字段的序列化Tokens
func jusonDeserializeField(varDecl: VarDecl, attrs: ?HashMap<String, Tokens>): Tokens {
    let map = match (attrs) {
        case Some(a) =>
            checkDeserAttrConflict(varDecl, a)
            a
        case None => 
            let exceptionStr = "Missing field \"${varDecl.identifier.value}\""
            return quote($(varDecl.identifier): match (jsonObject.get($(varDecl.identifier.value))) {
                case Some(v) => $(varDecl.declType).jusonDeserialize(v)
                case None => throw DeserializationException($(exceptionStr))
            })
    }
    // 处理skip属性
    if (map.get("skip")?[0].value == "all" || map.get("skip")?[0].value == "deserializing") {
        return quote()
    }
    // 处理name属性
    let varName = map.get("name")?[0].value ?? varDecl.identifier.value
    // 处理default属性
    match (map.get("default")) {
        case Some(d) =>
            quote($(varDecl.identifier): match (jsonObject.get($(varName))) {
                case Some(v) => $(varDecl.declType).jusonDeserialize(v)
                case None => $d
            })
        case None =>
            let exceptionStr = "Missing field \"${varName}\""
            quote($(varDecl.identifier): match (jsonObject.get($(varName))) {
                case Some(v) => $(varDecl.declType).jusonDeserialize(v)
                case None => throw DeserializationException($(exceptionStr))
            })
    }
}

// 检查name冲突
func checkVarNameConflict(varDecls: Array<VarDecl>, varAttrMap: HashMap<String, HashMap<String, Tokens>>): Unit {
    let nameVarMap = varDecls |> map {v => (v.identifier.value, v)} |> collectHashMap
    let existingNames = varDecls |> map {v => v.identifier.value} |> collectHashSet
    let conflictReports = ArrayList<() -> Unit>()
    for ((name, attrs) in varAttrMap) {
        let curr = name
        match (attrs.get("name")) {
            case Some(n) =>
                let value = n[0].value
                if (n.size == 1 && n[0].kind == STRING_LITERAL && existingNames.contains(value) && value != curr) {
                    conflictReports.append(
                        {
                        => diagReport(DiagReportLevel.ERROR, nameVarMap[value].toTokens(),
                            "Conflicting field name \"${n}\": existing field \"${curr}\" has been renamed to \"${n}\"",
                            "Conflicting field name \"${n}\": existing field \"${curr}\" has been renamed to \"${n}\"")
                    })

                }
            case None => ()
        }
    }
    if (conflictReports.size > 0) {
        for (report in conflictReports) {
            report()
        }
        throw ASTException("Conflicting field name")
    }
}

// 检查反序列化过程属性冲突
func checkDeserAttrConflict(varDecl: VarDecl, attrs: HashMap<String, Tokens>): Unit {
    let _ = varDecl
    let conflict = {
        kv1: String, kv2: String =>
        diagReport(DiagReportLevel.ERROR, varDecl.toTokens(), "Conflicting attributes: \"${kv1}\" and \"${kv2}\"",
            "Conflicting attributes: \"${kv1}\" and \"${kv2}\"")
        throw ASTException("Conflicting attributes: \"${kv1}\" and \"${kv2}\"")
    }
    if (attrs.get("required")?[0].value == "true" && attrs.get("skip")?[0].value == "all") { // required和skip=all冲突
        conflict("required=true", "skip=all")
    }
    if (attrs.get("required")?[0].value == "true" && attrs.get("skip")?[0].value == "deserializing") { // required和skip=deserializing冲突
        conflict("required=true", "skip=deserializing")
    }
    if (attrs.get("required")?[0].value == "true" && attrs.contains("default")) { // required和default冲突
        conflict("required=true", "default")
    }
}

// hasFuncs: 0-serialize, 1-deserialize
func collectVarAttrsHasFuncs(body: Body): (Array<VarDecl>, HashMap<String, HashMap<String, Tokens>>, Array<Bool>) {
    let varDecls = ArrayList<VarDecl>() // 收集var变量
    let hasFuncs = Array<Bool>(2, repeat: false) //判断是否已存在相关函数，[0]-serialize, [1]-deserialize
    let varAttrMap = HashMap<String, HashMap<String, Tokens>>() // 收集var的属性
    var declT: Decl = VarDecl() // 记录声明用于报错

    // 获取Field宏发送的信息
    let messages: ArrayList<MacroMessage> = getChildMessages("Field")
    // 收集变量属性到varAttrMap
    for (msg in messages) {
        let varName = msg.getString("variable-name")
        let varAttrs = msg.getString("variable-attrs").split(",")
        let attrMap = HashMap<String, Tokens>()
        for (a in varAttrs) {
            attrMap.put(a, msg.getTokens(a))
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
