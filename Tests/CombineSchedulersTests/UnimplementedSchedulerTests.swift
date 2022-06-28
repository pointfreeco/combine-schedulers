#if compiler(>=5.4)
  import Combine
  import CombineSchedulers
  import XCTest

  final class UnimplementedSchedulerTests: XCTestCase {
    func testFailure() {
      let scheduler = RunLoop.unimplemented

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
