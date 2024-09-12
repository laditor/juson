### @Juson案例
```cj
import std.collection.ArrayList
import std.time.DateTime
import juson.*

@Juson
class Product {
    @Field[name="商品名称"] // 自定义商品名称字段名
    var name: String

    @Field[default=0.0] // 商品价格默认值为0.0
    var price: Float64

    let category: ?String // 商品类别，可选字段，反序列化和序列化过程中默认值为None，对应JSON中的null

    @Field[default="该商品没有描述"] // 如果在反序列化时不提供该字段，默认值为"该商品没有描述"
    var description: String 
}

@Juson
struct Order {
    var orderId: Int64

    var status: String

    @Field[skip=deserializing] // 创建时间默认值为当前时间，跳过反序列化
    var createdAt: DateTime = DateTime.now()

    @Field[skip=all] // 跳过序列化和反序列化，系统日志不应暴露，也不应从外部修改
    var systemLog: String = "系统日志记录"

    @Field[skip=serializing] // 仅跳过序列化，缓存数据不会出现在输出的JSON中
    var cache: ?String

    @Field[name="商品列表"]
    var products: Array<Product>
}

main(): Int64 {
    // 创建订单和产品实例
    var product1 = Product(
        name: "手机",
        price: 6999.99,
        category: "电子产品",
        description: "这是一个很棒的手机"
    )
    var product2 = Product(
        name: "耳机",
        price: 299.99,
        category: "配件",
        description: "这是一个很棒的耳机"
    )
    
    var order = Order(
        orderId: 10001,
        status: "已支付",
        cache: "缓存数据",
        products: [product1, product2]
    )

    // 序列化：将订单对象转换为JSON字符串
    let jsonStr = order.jusonSerialize().toJsonString()
    println("序列化后的JSON: ${jsonStr}")  // cache字段不会出现在输出的JSON中

    // 反序列化：从JSON恢复为对象
    let json = @Json({
        "orderId": 10002,
        "status": "已发货",
        "createdAt": "2023-09-01", // 尝试修改创建时间
        "cache": "外部缓存数据",
        "商品列表": [
            { "商品名称": "平板电脑", "price": 4999.99, "category": "电子产品" },
            { "商品名称": "充电器", "price": 99.99, "category": "配件" }
        ]
    })

    let newOrder = Order.jusonDeserialize(json)
    println("反序列化后的订单ID: ${newOrder.orderId}")
    println("反序列化后的订单状态: ${newOrder.status}")
    println("反序列化后的创建时间: ${newOrder.createdAt}")
    println("反序列化后的缓存: ${newOrder.cache ?? "null"}")
    for (product in newOrder.products) {
        println("商品名称: ${product.name}, 价格: ${product.price}, 类别: ${product.category ?? "null"}, 描述: ${product.description}")
    }
    0
}

```
### @Json案例
```cj
import std.collection.{map, HashMap, collectArray}
import juson.*

main(): Int64 {
    let key1 = "key"
    let ofStr = {s: String => "[${s}]"}
    let numStr = "1, 2, 5, 12, 9, 4, 3.5"
    let info = HashMap<String, JusonSerializable>([
        ("name", "Fiona"),
        ("age", 40)
    ])
    
    let a = @Json(
        {
            "calculation": 1.0 + 2.0,  // 简单的数学表达式
            "repeated": "bbb" * 3,  // 字符串操作
            ofStr("ccc"): ofStr("ccc"),  // 函数表达式调用
            "key_transformed": numStr.split(",") |>
                map {i => i.trimAscii() + "g"} |> collectArray,  // 动态数组生成
            key1: "Dynamic key with a value",
            "null_value": null,  // null 值
            "infos": [info],  // 使用map动态生成对象
        }
    )

    println(a.toJsonString())
    return 0
}
```