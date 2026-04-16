#if canImport(Combine)
  import Combine
#elseif canImport(OpenCombineShim)
  import OpenCombineShim
#endif
#if canImport(Combine) || canImport(OpenCombineShim)
  import CombineSchedulers
  import XCTest

  final class ImmediateSchedulerTests: XCTestCase {
    func testSchedulesImmediately() {
      let scheduler = DispatchQueue.immediate
      var worked = 0

      scheduler.schedule { worked += 1 }
      XCTAssertEqual(worked, 1)

      scheduler.schedule(after: scheduler.now.advanced(by: 1)) { worked += 1 }
      XCTAssertEqual(worked, 2)

      _ = scheduler.schedule(after: scheduler.now.advanced(by: 1), interval: 1) { worked += 1 }
      XCTAssertEqual(worked, 3)
    }
  }
#endif
