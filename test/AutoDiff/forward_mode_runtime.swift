// RUN: %target_run_simple_swift_forward_mode_differentiation
// REQUIRES: executable_test

import StdlibUnittest

var ForwardModeTests = TestSuite("ForwardMode")

ForwardModeTests.test("Unary") {
  func func_to_diff(x: Float) -> Float {
    return x * x
  }
  let (y, differential) = valueWithDifferential(at: 4, in: func_to_diff)
  expectEqual(16, y)
  expectEqual(8, differential(1))
}

ForwardModeTests.test("Binary") {
  func func_to_diff(x: Float, y: Float) -> Float {
    return x * y
  }
  let (y, differential) =  valueWithDifferential(at: 4, 5, in: func_to_diff)
  expectEqual(20, y)
  expectEqual(9, differential(1, 1))
}

ForwardModeTests.test("BinaryWithLets") {
  func func_to_diff(x: Float, y: Float) -> Float {
    let a = x + y
    let b = a
    return b * -y
  }
  let (y, differential) =  valueWithDifferential(at: 4, 5, in: func_to_diff)
  expectEqual(-45, y)
  expectEqual(-19, differential(1, 1))
}

ForwardModeTests.test("UnaryWithVars") {
  @differentiable
  @_silgen_name("unary")
  func unary(x: Float) -> Float {
    var a = x
    var b = a + 1
    var c: Float = 2
    var d = a + b + c
    d = d + d
    return d
  }

  let (y, differential) = valueWithDifferential(at: 4, in: unary)
  expectEqual(22, y)
  expectEqual(4, differential(1))
}

runAllTests()
