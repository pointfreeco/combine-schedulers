#if canImport(Combine)
import Combine
import CombineSchedulers
import XCTest

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class ImmediateSchedulerTests: XCTestCase {
  func testSchedulesImmediately() {
    let scheduler = DispatchQueue.immediateScheduler
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
