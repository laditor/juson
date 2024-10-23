import std.process.Process

func stagePreTest(): Int64 {
    Process.current.setEnv("cjHeapSize", "2Gb")
    0
}

main(): Int64 {
    match (Process.current.arguments[0]) {
        case "pre-test" => stagePreTest()
        case _ => 0
    }
}