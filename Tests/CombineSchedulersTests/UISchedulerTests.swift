import OpenCombineShim
import CombineSchedulers
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

    var worked = false
    queue.async {
      XCTAssert(!Thread.isMainThread)
      UIScheduler.shared.schedule {
        XCTAssert(Thread.isMainThread)
        worked = true
        exp.fulfill()
      }
      XCTAssertFalse(worked)
    }

    self.wait(for: [exp], timeout: 1)

    XCTAssertTrue(worked)
  }
}
