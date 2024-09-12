import std.os.*

func stagePreTest(): Int64 {
    setEnv("cjHeapSize", "2Gb")
    0
}

main(): Int64 {
    match (getArgs()[0]) {
        case "pre-test" => stagePreTest()
        case _ => 0
    }
}