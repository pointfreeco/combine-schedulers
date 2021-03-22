#if canImport(Combine) && compiler(>=5.4)
  import Combine
  import CombineSchedulers
  import XCTest

  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  final class FailingSchedulerTests: XCTestCase {
    func testFailure() {
      let scheduler = RunLoop.failing

      XCTExpectFailure { _ = scheduler.now }
      XCTExpectFailure { _ = scheduler.minimumTolerance }
      XCTExpectFailure { scheduler.schedule(options: nil) {} }
      XCTExpectFailure {
        scheduler.schedule(after: .init(.init()), tolerance: .zero, options: nil) {}
      }
      _ = XCTExpectFailure {
        scheduler.schedule(after: .init(.init()), interval: 1, tolerance: .zero, options: nil) {}
      }
    }
  }
#endif
