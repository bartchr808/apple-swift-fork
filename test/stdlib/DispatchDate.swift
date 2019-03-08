// RUN: %empty-directory(%t)
// RUN: %target-build-swift %s -o %t/a.out
// RUN: %target-codesign %t/a.out
//
// RUN: %target-run %t/a.out
// REQUIRES: executable_test

// REQUIRES: libdispatch
// REQUIRES: foundation

import Dispatch
import Foundation
import StdlibUnittest

var DispatchAPI = TestSuite("DispatchAPI")

DispatchAPI.test("DispatchTime.addSubtractDateConstants") {
	var then = DispatchTime.now() + Date.distantFuture.timeIntervalSinceNow
	expectEqual(DispatchTime(uptimeNanoseconds: UInt64.max), then)

	then = DispatchTime.now() + Date.distantPast.timeIntervalSinceNow
	expectEqual(DispatchTime(uptimeNanoseconds: 1), then)

	then = DispatchTime.now() - Date.distantFuture.timeIntervalSinceNow
	expectEqual(DispatchTime(uptimeNanoseconds: 1), then)

	then = DispatchTime.now() - Date.distantPast.timeIntervalSinceNow
	expectEqual(DispatchTime(uptimeNanoseconds: UInt64.max), then)
}

DispatchAPI.test("DispatchWallTime.addSubtractDateConstants") {
	let distantPastRawValue = DispatchWallTime.distantFuture.rawValue - UInt64(1)

	var then = DispatchWallTime.now() + Date.distantFuture.timeIntervalSinceNow
	expectEqual(DispatchWallTime.distantFuture, then)

	then = DispatchWallTime.now() + Date.distantPast.timeIntervalSinceNow
	expectEqual(distantPastRawValue, then.rawValue)

	then = DispatchWallTime.now() - Date.distantFuture.timeIntervalSinceNow
	expectEqual(distantPastRawValue, then.rawValue)

	then = DispatchWallTime.now() - Date.distantPast.timeIntervalSinceNow
	expectEqual(DispatchWallTime.distantFuture, then)
}

runAllTests()
