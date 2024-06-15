#if canImport(Combine)
  import Combine
  import CombineSchedulers
  import ConcurrencyExtras
  import XCTest

  final class UISchedulerTests: XCTestCase {
    func testVoidsThreadHop() {
      var worked = false
      UIScheduler.shared.schedule { worked = true }
      XCTAssert(worked)
    }

    func testRunsOnMain() {
      let queue = DispatchQueue.init(label: "queue")
      let exp = self.expectation(description: "wait")

      let worked = LockIsolated(false)
      queue.async {
        XCTAssert(!Thread.isMainThread)
        UIScheduler.shared.schedule {
          XCTAssert(Thread.isMainThread)
          worked.setValue(true)
          exp.fulfill()
        }
        XCTAssertFalse(worked.value)
      }

      self.wait(for: [exp], timeout: 1)

      XCTAssertTrue(worked.value)
    }
  }
#endif
