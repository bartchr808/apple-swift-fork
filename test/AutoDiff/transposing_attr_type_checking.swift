// RUN: %target-swift-frontend -typecheck -verify %s

// ~~~~~~~~~~~~~ Test top-level functions. ~~~~~~~~~~~~~

func linearFunc(_ x: Float) -> Float {
  return x
}

@transposing(linearFunc, wrt: 0) // ok
func transposingLinearFunc(x: Float) -> Float {
  return x
}

func twoParams(_ x: Float, _ y: Double) -> Double {
  return Double(x) + y
}

@transposing(twoParams, wrt: 0) // ok
func twoParamsT1(_ y: Double, _ t: Double) ->  Float {
  return Float(t + y)
}

@transposing(twoParams, wrt: 1) // ok
func twoParamsT2(_ x: Float, _ t: Double) ->  Double {
  return Double(x) + t
}

@transposing(twoParams, wrt: (0, 1)) // ok
func twoParamsT3(_ t: Double) ->  (Float, Double) {
  return (Float(t), t)
}

func threeParams(_ x: Float, _ y: Double, _ z: Float) -> Double {
  return Double(x) + y
}

@transposing(threeParams, wrt: 0) // ok
func threeParamsT1(_ y: Double, _ z: Float, _ t: Double) -> Float {
  return Float(t + y) + z
}

@transposing(threeParams, wrt: 1) // ok
func threeParamsT2(_ x: Float, _ z: Float, _ t: Double) -> Double {
  return Double(x + z) + t
}

@transposing(threeParams, wrt: 2) // ok
func threeParamsT3(_ x: Float, _ y: Double, _ t: Double) -> Float {
  return Float(y + t) + x
}

@transposing(threeParams, wrt: (0, 1)) // ok
func threeParamsT4(_ z: Float, _ t: Double) -> (Float, Double) {
  return (z + Float(t), Double(z) + t)
}

@transposing(threeParams, wrt: (0, 2)) // ok
func threeParamsT5(_ y: Double, _ t: Double) -> (Float, Float) {
  let ret = Float(y + t)
  return (ret, ret)
}

@transposing(threeParams, wrt: (0, 1, 2)) // ok
func threeParamsT5(_ t: Double) -> (Float, Double, Float) {
  let ret = Float(t)
  return (ret, t, ret)
}

func generic<T: Differentiable>(x: T) -> T where T == T.TangentVector {
  return x
}

@transposing(generic, wrt: 0) // ok
func genericT<T: Differentiable>(x: T) -> T where T == T.TangentVector {
  return x
}

func withInt(x: Float, y: Int) -> Float {
  if y >= 0 {
    return x
  } else {
    return x
  }
}

@transposing(withInt, wrt: 0) // ok
func withIntT(x: Int, t: Float) -> Float {
  return t
}

func missingDiffSelfRequirement<T: AdditiveArithmetic>(x: T) -> T {
  return x
}

// expected-error @+1 {{'@transposing' attribute requires original function result to conform to 'Differentiable'}}
@transposing(missingDiffSelfRequirement, wrt: 0)
func missingDiffSelfRequirementT<T: AdditiveArithmetic>(x: T) -> T {
  return x
}

// TODO: error should be "can only transpose with respect to parameters that conform to 'Differentiable' and where 'Int == Int.TangentVector'"
// but currently there is an assertion failure.
/*func missingSelfRequirement<T: Differentiable>(x: T) 
  -> T where T.TangentVector == T {
  return x
}

@transposing(missingSelfRequirement, wrt: 0)
func missingSelfRequirementT<T: Differentiable>(x: T) -> T {
  return x
}*/

func differentGenericConstraint<T: Differentiable & BinaryFloatingPoint>(x: T)
-> T where T == T.TangentVector {
  return x
}

// expected-error @+2 {{type 'T' does not conform to protocol 'BinaryFloatingPoint'}}
// expected-error @+1 {{could not find function 'differentGenericConstraint' with expected type '<T where T : Differentiable, T == T.TangentVector> (T) -> T'}}
@transposing(differentGenericConstraint, wrt: 0)
func differentGenericConstraintT<T: Differentiable>(x: T) 
-> T where T == T.TangentVector {
  return x
}

func transposingInt(x: Float, y: Int) -> Float {
  if y >= 0 {
    return x
  } else {
    return x
  }
}

// expected-error @+1 {{can only transpose with respect to parameters that conform to 'Differentiable' and where 'Int == Int.TangentVector'}}
@transposing(transposingInt, wrt: 1) 
func transposingIntT1(x: Float, t: Float) -> Int {
  return Int(x)
}


// expected-error @+1 {{'@transposing' attribute requires original function result to conform to 'Differentiable'}}
@transposing(transposingInt, wrt: 0)
func tangentNotLast(t: Float, y: Int) -> Float {
  return t
}

// ~~~~~~~~~~~~~ Test methods. ~~~~~~~~~~~~~

// Method no parameters.
extension Float {
  func getDouble() -> Double {
      return Double(self)
  }
}

extension Double {
  @transposing(Float.getDouble, wrt: self)
  func structTranspose() -> Float {
    return Float(self)
  }
}

// Method with one parameter.
extension Float {
  func adding(_ double: Double) -> Float {
    return self + Float(double)
  }
    
  @transposing(Float.adding, wrt: (self, 0))
  func tran(t: Float) -> (Float, Double) {
    return (t, Double(t))
  }
}

// Static method.
struct A : Differentiable & AdditiveArithmetic {
  public typealias TangentVector = A
  var x: Double
  static prefix func -(a: A) -> A {
    return A(x: -a.x)
  }
}

extension A {
  @transposing(A.-, wrt: 0)
  static func negationT(a: A) -> A {
    return A(x: -a.x)
  }
}

// Method with 3 parameters.
extension Float {
  func threeParams(_ x: Float, _ y: Double, _ z: Float) -> Double {
    return Double(self) + Double(x) + y
  }

  @transposing(Float.threeParams, wrt: 0) // ok
  func threeParamsT1(_ y: Double, _ z: Float, _ t: Double) -> Float {
    return self + Float(t + y) + z
  }

  @transposing(Float.threeParams, wrt: 1) // ok
  func threeParamsT2(_ x: Float, _ z: Float, _ t: Double) -> Double {
    return Double(self) + Double(x + z) + t
  }

  @transposing(Float.threeParams, wrt: 2) // ok
  func threeParamsT3(_ x: Float, _ y: Double, _ t: Double) -> Float {
    return self + Float(y + t) + x
  }

  @transposing(Float.threeParams, wrt: (0, 1)) // ok
  func threeParamsT4(_ z: Float, _ t: Double) -> (Float, Double) {
    return (self + z + Float(t), Double(self) + Double(z) + t)
  }

  @transposing(Float.threeParams, wrt: (0, 2)) // ok
  func threeParamsT5(_ y: Double, _ t: Double) -> (Float, Float) {
    let ret = self + Float(y + t)
    return (ret, ret)
  }

  @transposing(Float.threeParams, wrt: (0, 1, 2)) // ok
  func threeParamsT5(_ t: Double) -> (Float, Double, Float) {
    return (self + Float(t), Double(self) +  t, self + Float(t))
  }
}

extension Double {
  @transposing(Float.threeParams, wrt: self) // ok
  func threeParamsT6(_ x: Float, _ y: Double, _ z: Float) -> Float {
    return Float(self + y) + x
  }

  // @transposing(Float.threeParams, wrt: (self, 0)) // ok
  // func threeParamsT7(_ y: Double, _ z: Float, _ t: Double) -> Float {
  //   return Float(self) + Float(t + y) + z
  // }

  // @transposing(Float.threeParams, wrt: (self, 1)) // ok
  // func threeParamsT8(_ x: Float, _ z: Float, _ t: Double) -> Double {
  //   return self + Double(x + z) + t
  // }

  // @transposing(Float.threeParams, wrt: (self, 2)) // ok
  // func threeParamsT9(_ x: Float, _ y: Double, _ t: Double) -> Float {
  //   return Float(self) + Float(y + t) + x
  // }

  // @transposing(Float.threeParams, wrt: (self, 0, 1)) // ok
  // func threeParamsT10(_ z: Float, _ t: Double) -> (Float, Double) {
  //   return (Float(self) + z + Float(t), self + Double(z) + t)
  // }

  // @transposing(Float.threeParams, wrt: (self, 0, 2)) // ok
  // func threeParamsT11(_ y: Double, _ t: Double) -> (Float, Float) {
  //   let ret = Float(self) + Float(y + t)
  //   return (ret, ret)
  // }

  // @transposing(Float.threeParams, wrt: (self, 0, 1, 2)) // ok
  // func threeParamsT12(_ t: Double) -> (Float, Double, Float) {
  //   return (Float(self + t), self +  t, Float(self + t))
  // }
}