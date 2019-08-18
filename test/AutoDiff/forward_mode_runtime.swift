// RUN: %target_run_simple_swift_forward_mode_differentiation
// REQUIRES: executable_test

import StdlibUnittest
import DifferentiationUnittest

var ForwardModeTests = TestSuite("ForwardMode")

ForwardModeTests.test("Identity") {
  func func_to_diff(x: Float) -> Float {
    return x
  }
  let (y, differential) = valueWithDifferential(at: 4, in: func_to_diff)
  expectEqual(4, y)
  expectEqual(1, differential(1))
}
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
  let (y, differential) = valueWithDifferential(at: 4, 5, in: func_to_diff)
  expectEqual(20, y)
  expectEqual(9, differential(1, 1))
}

ForwardModeTests.test("BinaryWithLets") {
  func func_to_diff(x: Float, y: Float) -> Float {
    let a = x + y
    let b = a
    return b * -y
  }
  let (y, differential) = valueWithDifferential(at: 4, 5, in: func_to_diff)
  expectEqual(-45, y)
  expectEqual(-19, differential(1, 1))
}

//===----------------------------------------------------------------------===//
// Functions with variables
//===----------------------------------------------------------------------===//

ForwardModeTests.test("UnaryWithVars") {
  func unary(x: Float) -> Float {
    var a = x
    a = x
    var b = a + 2
    b = b - 1
    let c: Float = 3
    var d = a + b + c - 1
    d = d + d
    return d
  }

  let (y, differential) = valueWithDifferential(at: 4, in: unary)
  expectEqual(22, y)
  expectEqual(4, differential(1))
}

//===----------------------------------------------------------------------===//
// Functions with basic struct
//===----------------------------------------------------------------------===//

struct A: Differentiable & AdditiveArithmetic {
    var x: Float
  }

ForwardModeTests.test("StructInit") {
  func structInit(x: Float) -> A {
    return A(x: 2 * x)
  }

  let (y, differential) = valueWithDifferential(at: 4, in: structInit)
  expectEqual(A(x: 8), y)
  expectEqual(A(x: 2), differential(1))
}

ForwardModeTests.test("StructExtract") {
  func structExtract(x: A) -> Float {
    return 2 * x.x
  }

  let (y, differential) = valueWithDifferential(
    at: A(x: 4), 
    in: structExtract) 
  expectEqual(8, y)
  expectEqual(2, differential(A(x: 1)))
}

ForwardModeTests.test("LocalStructVariable") {
  func structExtract(x: A) -> A {
    let a = A(x: 2 * x.x) // 2x
    var b = A(x: a.x + 2) // 2x + 2
    b = A(x: b.x + a.x) // 2x + 2 + 2x = 4x + 2
    return b
  }

  let (y, differential) = valueWithDifferential(
    at: A(x: 4), 
    in: structExtract) 
  expectEqual(A(x: 18), y)
  expectEqual(A(x: 4), differential(A(x: 1)))
}

//===----------------------------------------------------------------------===//
// Functions with methods
//===----------------------------------------------------------------------===//

extension A {
  func noParamMethodA() -> A {
    return A(x: 2 * x)
  }

  func noParamMethodx() -> Float {
    return 2 * x
  }

  static func *(lhs: A, rhs: A) -> A {
    return A(x: lhs.x * rhs.x)
  }

  func complexBinaryMethod(u: A, v: Float) -> A {
    var b: A = u * A(x: 2)  // A(x: u * 2)
    b.x = b.x * v        // A(x: u * 2 * v)
    let c = b.x + 1      // u * 2 * v + 1

    // A(x: u * 2 * v + 1 + u * 2 * v) = A(x: x * (4uv + 1))
    return A(x: x * (c + b.x))
  }
}

ForwardModeTests.test("noParamMethodA") {
  let (y, differential) = valueWithDifferential(at: A(x: 4)) { x in
    x.noParamMethodA()
  }
  expectEqual(A(x: 8), y)
  expectEqual(A(x: 2), differential(A(x: 1)))
}

ForwardModeTests.test("noParamMethodx") {
  let (y, differential) = valueWithDifferential(at: A(x: 4)) { x in
    x.noParamMethodx()
  }
  expectEqual(8, y)
  expectEqual(2, differential(A(x: 1)))
}

ForwardModeTests.test("complexBinaryMethod") {
  let (y, differential) = valueWithDifferential(at: A(x: 4), A(x: 5), 3) { 
    (x, y, z) in
    // derivative = A(x: 4uv + 4xv + 4ux + 1) = 4*5*3 + 4*4*3 + 4*5*4 + 1 = 189
    x.complexBinaryMethod(u: y, v: z)
  }
  expectEqual(A(x: 244), y)
  expectEqual(A(x: 189), differential(A(x: 1), A(x: 1), 1))
}

ForwardModeTests.test("TrackedIdentity") {
  func identity(x: Tracked<Float>) -> Tracked<Float> {
    return x
  }
  let (y, differential) = valueWithDifferential(at: 4, in: identity)
  expectEqual(4, y)
  expectEqual(1, differential(1))
}

ForwardModeTests.test("TrackedAddition") {
  func add(x: Tracked<Float>, y: Tracked<Float>) -> Tracked<Float> {
    return x + y
  }
  let (y, differential) = valueWithDifferential(at: 4, 5, in: add)
  expectEqual(9, y)
  expectEqual(2, differential(1, 1))
}

ForwardModeTests.test("TrackedDivision") {
  func divide(x: Tracked<Float>, y: Tracked<Float>) -> Tracked<Float> {
    return x / y
  }
  let (y, differential) = valueWithDifferential(at: 10, 5, in: divide)
  expectEqual(2, y)
  expectEqual(-0.2, differential(1, 1))
}

ForwardModeTests.test("TrackedMultipleMultiplication") {
  func add(x: Tracked<Float>, y: Tracked<Float>) -> Tracked<Float> {
    return x * y * x
  }
  let (y, differential) = valueWithDifferential(at: 4, 5, in: add)
  expectEqual(80, y)
  // 2yx+xx
  expectEqual(56, differential(1, 1))
}

ForwardModeTests.test("TrackedWithLets") {
  func add(x: Tracked<Float>, y: Tracked<Float>) -> Tracked<Float> {
    let a = x + y
    let b = a * a // (x+y)^2
    let c = b / x + y // (x+y)^2/x+y
    return c
  }
  // (3x^2+2xy-y^2)/x^2+1
  let (y, differential) = valueWithDifferential(at: 4, 5, in: add)
  expectEqual(25.25, y)
  expectEqual(4.9375, differential(1, 1))
}

//===----------------------------------------------------------------------===//
// Tuples
//===----------------------------------------------------------------------===//

ForwardModeTests.test("SimpleTupleExtractLet") {
  func foo(_ x: Float) -> Float {
    let tuple = (2*x, x)
    return tuple.0
  }
  let (y, differential) = valueWithDifferential(at: 4, in: foo)
  expectEqual(8, y)
  expectEqual(2, differential(1))
}

ForwardModeTests.test("SimpleTupleExtractVar") {
  func foo(_ x: Float) -> Float {
    let tuple = (2*x, x)
    return tuple.0
  }
  let (y, differential) = valueWithDifferential(at: 4, in: foo)
  expectEqual(8, y)
  expectEqual(2, differential(1))
}

ForwardModeTests.test("TupleSideEffects") {
  func foo(_ x: Float) -> Float {
    var tuple = (x, x)
    tuple.0 = tuple.0 * x
    return x * tuple.0
  }
  expectEqual(27, derivative(at: 3, in: foo))

  func fifthPower(_ x: Float) -> Float {
    var tuple = (x, x)
    tuple.0 = tuple.0 * x
    tuple.1 = tuple.0 * x
    return tuple.0 * tuple.1
  }
  expectEqual(405, derivative(at: 3, in: fifthPower))

  func nested(_ x: Float) -> Float {
    var tuple = ((x, x), x)
    tuple.0.0 = tuple.0.0 * x
    tuple.0.1 = tuple.0.0 * x
    return tuple.0.0 * tuple.0.1
  }
  expectEqual(405, derivative(at: 3, in: nested))

  // FIXME(TF-201): Update after reabstraction thunks can be directly differentiated.
  /*
  func generic<T : Differentiable & AdditiveArithmetic>(_ x: T) -> T {
    var tuple = (x, x)
    tuple.0 += x
    tuple.1 += x
    return tuple.0 + tuple.0
  }
  expectEqual(1, derivative(at: 3.0, in: generic))
  */
}

// Tests TF-321.
ForwardModeTests.test("TupleNonDifferentiableElements") {
  // @differentiable
  // func foo(_ x: Float) -> Float {
  //   var tuple = (x, 1)
  //   tuple.0 = x
  //   tuple.1 = 1
  //   return tuple.0
  // }
  // expectEqual(1, derivative(at: 1, in: foo))

  // func bar(_ x: Float) -> Float {
  //   var tuple: (Int, Int, Float, Float) = (1, 1, x, x)
  //   tuple.0 = 1
  //   tuple.1 = 1
  //   tuple.3 = x
  //   return tuple.3
  // }
  // expectEqual(1, derivative(at: 1, in: bar))

  struct Wrapper<T> {
    @differentiable(where T : Differentiable)
    func baz(_ x: T) -> T {
      var tuple = (1, 1, x, 1)
      tuple.0 = 1
      tuple.2 = x
      tuple.3 = 1
      return tuple.2
    }
  }
  expectEqual(1, derivative(at: Float(1), in: { x -> Float in
    let wrapper = Wrapper<Float>()
    return wrapper.baz(x)
  }))
}

//===----------------------------------------------------------------------===//
// Arrays
//===----------------------------------------------------------------------===//
// ForwardModeTests.test("IdentityArrayInit") {
//   func foo(_ x: Float) -> [Float] {
//     let a = [x]
//     return a
//   }
//   let (y, differential) = valueWithDifferential(at: 5, in: foo)
//   expectEqual([5.0], y)
//   expectEqual([1.0], differential(1))
// }

//===----------------------------------------------------------------------===//
// Generics
//===----------------------------------------------------------------------===//

// struct Tensor<Scalar : FloatingPoint & Differentiable> 
//   : VectorProtocol, Differentiable {
//   // NOTE: `value` must have type with known size (e.g. `Float`, not `Scalar`)
//   // until differentiation has indirect passing support.
//   var value: Float
//   init(_ value: Float) { self.value = value }
// }

// ForwardModeTests.test("GenericIdentity") {
//   func identity<T : Differentiable>(_ x: T) -> T {
//     return x
//   }
//   let (y, differential) = valueWithDifferential(at: 4) { (x: Float) in 
//     identity(x) 
//   }
//   expectEqual(4, y)
//   expectEqual(1, differential(1))
// }

// ForwardModeTests.test("GenericTensorIdentity") {
//   func identity<T : FloatingPoint & Differentiable>(
//     _ x: Tensor<T>) -> Tensor<T> {
//     return x
//   }
//   let (y, differential) = valueWithDifferential(at: 4) { (x: Float) in 
//     identity(Tensor<Float>(x)) 
//   }
//   expectEqual(Tensor<Float>(4), y)
//   expectEqual(Tensor<Float>(1), differential(1))
// }

// ForwardModeTests.test("GenericTensorPlus") {
//   func plus<T : FloatingPoint & Differentiable>(_ x: Tensor<T>) -> Float {
//     return x.value + x.value
//   }
//   let (y, differential) = valueWithDifferential(at: 4) { (x: Float) in 
//     plus(Tensor<Float>(x)) 
//   }
//   expectEqual(8, y)
//   expectEqual(2, differential(1))
// }

// ForwardModeTests.test("GenericTensorBinaryInput") {
//   func binary<T : FloatingPoint & Differentiable>(
//     _ x: Tensor<T>, _ y: Tensor<T>) -> Float {
//     return x.value * y.value
//   }
//   let (y, differential) = valueWithDifferential(at: 4, 5) { 
//     (x: Float, y: Float) in 
//     binary(Tensor<Float>(x), Tensor<Float>(y)) 
//   }
//   expectEqual(20, y)
//   expectEqual(9, differential(1, 1))
// }

// ForwardModeTests.test("GenericTensorWithLets") {
//   func binary<T : FloatingPoint & Differentiable>(
//     _ x: Tensor<T>, _ y: Tensor<T>) -> Float {
//     let a = Tensor<T>(x.value)
//     let b = Tensor<T>(y.value)
//     return a.value * b.value
//   }
//   let (y, differential) = valueWithDifferential(at: 4, 5) { 
//     (x: Float, y: Float) in 
//     binary(Tensor<Float>(x), Tensor<Float>(y)) 
//   }
//   expectEqual(20, y)
//   expectEqual(9, differential(1, 1))
// }

// ForwardModeTests.test("GenericTensorWithVars") {
//   func binary<T : FloatingPoint & Differentiable>(
//     _ x: Tensor<T>, _ y: Tensor<T>) -> Float {
//     var a = Tensor<T>(x.value)
//     var b = Tensor<T>(y.value)
//     b = a
//     a = Tensor<T>(y.value)
//     return a.value * b.value
//   }
//   let (y, differential) = valueWithDifferential(at: 4, 5) { 
//     (x: Float, y: Float) in 
//     binary(Tensor<Float>(x), Tensor<Float>(y)) 
//   }
//   expectEqual(20, y)
//   expectEqual(9, differential(1, 1))
// }

// // Test case where associated derivative function's requirements are met.
// extension Tensor where Scalar : Numeric {
//   @differentiable(wrt: self where Scalar : Differentiable & FloatingPoint)
//   func mean() -> Tensor {
//     return self
//   }

//   @differentiable(wrt: self where Scalar : Differentiable & FloatingPoint)
//   func variance() -> Tensor {
//     return mean() // ok
//   }
// }
// _ = differential(at: Tensor<Float>(1), in: { $0.variance() })

// // Tests TF-508: differentiation requirements with dependent member types.
// protocol TF_508_Proto {
//   associatedtype Scalar
// }
// extension TF_508_Proto where Scalar : FloatingPoint {
//   @differentiable(
//     jvp: jvpAdd
//     where Self : Differentiable, Scalar : Differentiable,
//           // Conformance requirement with dependent member type.
//           Self.TangentVector : TF_508_Proto
//   )
//   static func +(lhs: Self, rhs: Self) -> Self {
//     return lhs
//   }

//   @differentiable(
//     jvp: jvpSubtract
//     where Self : Differentiable, Scalar : Differentiable,
//           // Same-type requirement with dependent member type.
//           Self.TangentVector == Float
//   )
//   static func -(lhs: Self, rhs: Self) -> Self {
//     return lhs
//   }
// }
// extension TF_508_Proto where Self : Differentiable,
//                              Scalar : FloatingPoint & Differentiable,
//                              Self.TangentVector : TF_508_Proto {
//   static func jvpAdd(lhs: Self, rhs: Self)
//       -> (Self, (TangentVector, TangentVector) -> TangentVector) {
//     return (lhs, { (dlhs, drhs) in dlhs })
//   }
// }
// extension TF_508_Proto where Self : Differentiable,
//                              Scalar : FloatingPoint & Differentiable,
//                              Self.TangentVector == Float {
//   static func jvpSubtract(lhs: Self, rhs: Self)
//       -> (Self, (TangentVector, TangentVector) -> TangentVector) {
//     return (lhs, { (dlhs, drhs) in dlhs })
//   }
// }

// struct TF_508_Struct<Scalar : AdditiveArithmetic>
//   : TF_508_Proto, AdditiveArithmetic {}
// extension TF_508_Struct : Differentiable where Scalar : Differentiable {
//   typealias TangentVector = TF_508_Struct
// }

// func TF_508() {
//   let x = TF_508_Struct<Float>()
//   // Test conformance requirement with dependent member type.
//   _ = differential(at: x, in: { 
//     (x: TF_508_Struct<Float>) -> TF_508_Struct<Float> in
//     return x + x
//   })
//   // Test same-type requirement with dependent member type.
//   _ = differential(at: x, in: { 
//     (x: TF_508_Struct<Float>) -> TF_508_Struct<Float> in
//     return x - x
//   })
// }

// // TF-523
// struct TF_523_Struct : Differentiable & AdditiveArithmetic {
//   var a: Float = 1
//   typealias TangentVector = TF_523_Struct
//   typealias AllDifferentiableVariables = TF_523_Struct
// }

// @differentiable
// func TF_523_f(_ x: TF_523_Struct) -> Float {
//   return x.a * 2
// }

// // TF-534: Thunk substitution map remapping.
// protocol TF_534_Layer : Differentiable {
//   associatedtype Input : Differentiable
//   associatedtype Output : Differentiable

//   @differentiable
//   func callAsFunction(_ input: Input) -> Output
// }
// struct TF_534_Tensor<Scalar> : Differentiable {}

// func TF_534<Model: TF_534_Layer>(
//   _ model: inout Model, inputs: Model.Input
// ) -> TF_534_Tensor<Float> where Model.Output == TF_534_Tensor<Float> {
//   return valueWithDifferential(at: model) { model -> Model.Output in
//     return model(inputs)
//   }.0
// }

// // TODO: uncomment once control flow is supported in forward mode.
// // TF-652: Test VJPEmitter substitution map generic signature.
// // The substitution map should have the VJP's generic signature, not the
// // original function's.
// // struct TF_652<Scalar> {}
// // extension TF_652 : Differentiable where Scalar : FloatingPoint {}

// // @differentiable(wrt: x where Scalar: FloatingPoint)
// // func test<Scalar: Numeric>(x: TF_652<Scalar>) -> TF_652<Scalar> {
// //   for _ in 0..<10 {
// //     let _ = x
// //   }
// //   return x
// // }

// // Tracked Generic.

// ForwardModeTests.test("GenericTrackedIdentity") {
//   func identity<T : Differentiable>(_ x: Tracked<T>) -> Tracked<T> {
//     return x
//   }
//   let (y, differential) = valueWithDifferential(at: 4) { (x: Float) in
//     identity(Tracked(x))
//   }
//   expectEqual(4, y)
//   expectEqual(1, differential(1))
// }

// ForwardModeTests.test("GenericTrackedBinaryAdd") {
//   func add<T>(_ x: Tracked<T>, _ y: Tracked<T>) -> Tracked<T>
//     where T: Differentiable, T == T.TangentVector {
//     return x + y
//   }
//   let (y, differential) = valueWithDifferential(at: 4, 5) { 
//     (x: Float, y: Float) in
//     add(Tracked(x), Tracked(y))
//   }
//   expectEqual(9, y)
//   expectEqual(2, differential(1, 1))
// }

// ForwardModeTests.test("GenericTrackedBinaryLets") {
//   func add<T>(_ x: Tracked<T>, _ y: Tracked<T>) -> Tracked<T>
//     where T: Differentiable & SignedNumeric,
//           T == T.TangentVector,
//           T == T.Magnitude {
//     let a = x * y // xy
//     let b = a + a // 2xy
//     return b + b // 4xy
//   }
//   // 4y + 4x
//   let (y, differential) = valueWithDifferential(at: 4, 5) { (x: Float, y: Float) in
//     add(Tracked(x), Tracked(y))
//   }
//   expectEqual(80, y)
//   expectEqual(36, differential(1, 1))
// }

// ForwardModeTests.test("GenericTrackedBinaryVars") {
//   func add<T>(_ x: Tracked<T>, _ y: Tracked<T>) -> Tracked<T>
//     where T: Differentiable & SignedNumeric,
//           T == T.TangentVector,
//           T == T.Magnitude {
//     var a = x * y // xy
//     a = a + a // 2xy
//     var b = x
//     b = a
//     return b + b // 4xy
//   }
//   // 4y + 4x
//   let (y, differential) = valueWithDifferential(at: 4, 5) { (x: Float, y: Float) in
//     add(Tracked(x), Tracked(y))
//   }
//   expectEqual(80, y)
//   expectEqual(36, differential(1, 1))
// }

ForwardModeTests.test("Conditionals") {
  // func cond1(_ x: Float) -> Float {
  //   if x > 0 {
  //     return x * x
  //   }
  //   return x + x
  // }
  // expectEqual(8, derivative(at: 4, in: cond1))
  // expectEqual(2, derivative(at: -10, in: cond1))

  // func cond2(_ x: Float) -> Float {
  //   let y: Float
  //   if x > 0 {
  //     y = x * x
  //   } else if x == -1337 {
  //     y = 0
  //   } else {
  //     y = x + x
  //   }
  //   return y
  // }
  // expectEqual(8, derivative(at: 4, in: cond2))
  // expectEqual(2, derivative(at: -10, in: cond2))
  // expectEqual(0, derivative(at: -1337, in: cond2))

  // func cond2_var(_ x: Float) -> Float {
  //   var y: Float = x
  //   if x > 0 {
  //     y = y * x
  //   } else if x == -1337 {
  //     y = x // Dummy assignment; shouldn't affect computation.
  //     y = x // Dummy assignment; shouldn't affect computation.
  //     y = 0
  //   } else {
  //     y = x + y
  //   }
  //   return y
  // }
  // expectEqual(8, derivative(at: 4, in: cond2_var))
  // expectEqual(2, derivative(at: -10, in: cond2_var))
  // expectEqual(0, derivative(at: -1337, in: cond2_var))

  // func cond3(_ x: Float, _ y: Float) -> Float {
  //   if x > 0 {
  //     return x * y
  //   }
  //   return y - x
  // }
  // expectEqual(9, derivative(at: 4, 5, in: cond3))
  // expectEqual(0, derivative(at: -3, -2, in: cond3))

  // func cond_tuple(_ x: Float) -> Float {
  //   // Convoluted function returning `x + x`.
  //   let y: (Float, Float) = (x, x)
  //   if x > 0 {
  //     return y.0 + y.1
  //   }
  //   return y.0 + y.0 - y.1 + y.0
  // }
  // expectEqual((8, 2), valueWithDerivative(at: 4, in: cond_tuple))
  // expectEqual((-20, 2), valueWithDerivative(at: -10, in: cond_tuple))
  // expectEqual((-2674, 2), valueWithDerivative(at: -1337, in: cond_tuple))

  // func cond_tuple2(_ x: Float) -> Float {
  //   // Convoluted function returning `x + x`.
  //   let y: (Float, Float) = (x, x)
  //   let y0 = y.0
  //   if x > 0 {
  //     let y1 = y.1
  //     return y0 + y1
  //   }
  //   let y0_double = y0 + y.0
  //   let y1 = y.1
  //   return y0_double - y1 + y.0
  // }
  // expectEqual((8, 2), valueWithDerivative(at: 4, in: cond_tuple2))
  // expectEqual((-20, 2), valueWithDerivative(at: -10, in: cond_tuple2))
  // expectEqual((-2674, 2), valueWithDerivative(at: -1337, in: cond_tuple2))

  // func cond_tuple_var(_ x: Float) -> Float {
  //   // Convoluted function returning `x + x`.
  //   var y: (Float, Float) = (x, x)
  //   var z: (Float, Float) = (x + x, x - x)
  //   if x > 0 {
  //     var w = (x, x)
  //     y.0 = w.1
  //     y.1 = w.0
  //     z.0 = z.0 - y.0
  //     z.1 = z.1 + y.0
  //   } else {
  //     z = (x, x)
  //   }
  //   return y.0 + y.1 - z.0 + z.1
  // }
  // expectEqual((8, 2), valueWithDerivative(at: 4, in: cond_tuple_var))
  // expectEqual((-20, 2), valueWithDerivative(at: -10, in: cond_tuple_var))
  // expectEqual((-2674, 2), valueWithDerivative(at: -1337, in: cond_tuple_var))

  // func cond_nestedtuple_var(_ x: Float) -> Float {
  //   // Convoluted function returning `x + x`.
  //   var y: (Float, Float) = (x + x, x - x)
  //   var z: ((Float, Float), Float) = (y, x)
  //   if x > 0 {
  //     var w = (x, x)
  //     y.0 = w.1
  //     y.1 = w.0
  //     z.0.0 = z.0.0 - y.0
  //     z.0.1 = z.0.1 + y.0
  //   } else {
  //     z = ((y.0 - x, y.1 + x), x)
  //   }
  //   return y.0 + y.1 - z.0.0 + z.0.1
  // }
  // expectEqual((8, 2), valueWithDerivative(at: 4, in: cond_nestedtuple_var))
  // expectEqual((-20, 2), valueWithDerivative(at: -10, in: cond_nestedtuple_var))
  // expectEqual((-2674, 2), valueWithDerivative(at: -1337, in: cond_nestedtuple_var))

  // struct FloatPair : Differentiable {
  //   var first, second: Float
  //   init(_ first: Float, _ second: Float) {
  //     self.first = first
  //     self.second = second
  //   }
  // }

  // struct Pair<T : Differentiable, U : Differentiable> : Differentiable {
  //   var first: T
  //   var second: U
  //   init(_ first: T, _ second: U) {
  //     self.first = first
  //     self.second = second
  //   }
  // }

  // func cond_struct(_ x: Float) -> Float {
  //   // Convoluted function returning `x + x`.
  //   let y = FloatPair(x, x)
  //   if x > 0 {
  //     return y.first + y.second
  //   }
  //   return y.first + y.first - y.second + y.first
  // }
  // expectEqual((8, 2), valueWithDerivative(at: 4, in: cond_struct))
  // expectEqual((-20, 2), valueWithDerivative(at: -10, in: cond_struct))
  // expectEqual((-2674, 2), valueWithDerivative(at: -1337, in: cond_struct))

  // func cond_struct2(_ x: Float) -> Float {
  //   // Convoluted function returning `x + x`.
  //   let y = FloatPair(x, x)
  //   let y0 = y.first
  //   if x > 0 {
  //     let y1 = y.second
  //     return y0 + y1
  //   }
  //   let y0_double = y0 + y.first
  //   let y1 = y.second
  //   return y0_double - y1 + y.first
  // }
  // expectEqual((8, 2), valueWithDerivative(at: 4, in: cond_struct2))
  // expectEqual((-20, 2), valueWithDerivative(at: -10, in: cond_struct2))
  // expectEqual((-2674, 2), valueWithDerivative(at: -1337, in: cond_struct2))

  // func cond_struct_var(_ x: Float) -> Float {
  //   // Convoluted function returning `x + x`.
  //   var y = FloatPair(x, x)
  //   var z = FloatPair(x + x, x - x)
  //   if x > 0 {
  //     var w = y
  //     y.first = w.second
  //     y.second = w.first
  //     z.first = z.first - y.first
  //     z.second = z.second + y.first
  //   } else {
  //     z = FloatPair(x, x)
  //   }
  //   return y.first + y.second - z.first + z.second
  // }
  // expectEqual((8, 2), valueWithDerivative(at: 4, in: cond_struct_var))
  // expectEqual((-20, 2), valueWithDerivative(at: -10, in: cond_struct_var))
  // expectEqual((-2674, 2), valueWithDerivative(at: -1337, in: cond_struct_var))

  // func cond_nestedstruct_var(_ x: Float) -> Float {
  //   // Convoluted function returning `x + x`.
  //   var y = FloatPair(x + x, x - x)
  //   var z = Pair(y, x)
  //   if x > 0 {
  //     var w = FloatPair(x, x)
  //     y.first = w.second
  //     y.second = w.first
  //     z.first.first = z.first.first - y.first
  //     z.first.second = z.first.second + y.first
  //   } else {
  //     z = Pair(FloatPair(y.first - x, y.second + x), x)
  //   }
  //   return y.first + y.second - z.first.first + z.first.second
  // }
  // expectEqual((8, 2), valueWithDerivative(at: 4, in: cond_nestedstruct_var))
  // expectEqual((-20, 2), valueWithDerivative(at: -10, in: cond_nestedstruct_var))
  // expectEqual((-2674, 2), valueWithDerivative(at: -1337, in: cond_nestedstruct_var))
}

runAllTests()
