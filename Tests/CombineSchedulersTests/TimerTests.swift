#if canImport(Combine)
import Combine
import CombineSchedulers
import XCTest

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class TimerTests: XCTestCase {
  var cancellables: Set<AnyCancellable> = []

  override func tearDown() {
    super.tearDown()
    self.cancellables.removeAll()
  }

  func testWithDispatchQueue() {
    var output: [Int] = []
    let timerExpectation = self.expectation(description: "DispatchQueueTimer")
    timerExpectation.expectedFulfillmentCount = 3

    DispatchQueue.main.timerPublisher(every: 0.1)
      .autoconnect()
      .sink { _ in
        output.append(output.count)
        timerExpectation.fulfill()
      }
      .store(in: &self.cancellables)

    XCTAssertEqual(output, [])
    self.wait(for: [timerExpectation], timeout: 1)
    XCTAssertEqual(output, [0, 1, 2])
  }

  func testWithRunLoop() {
    var output: [Int] = []
    let timerExpectation = self.expectation(description: "RunLoopTimer")
    timerExpectation.expectedFulfillmentCount = 3

    Publishers.Timer(every: 0.1, scheduler: RunLoop.main)
      .autoconnect()
      .sink { _ in
        output.append(output.count)
        timerExpectation.fulfill()
      }
      .store(in: &self.cancellables)

    XCTAssertEqual(output, [])
    self.wait(for: [timerExpectation], timeout: 1)
    XCTAssertEqual(output, [0, 1, 2])
  }

  func testWithTestScheduler() {
    let scheduler = DispatchQueue.testScheduler
    var output: [UInt64] = []

    Publishers.Timer(every: 1, scheduler: scheduler)
      .autoconnect()
      .sink { _ in output.append(scheduler.now.dispatchTime.uptimeNanoseconds) }
      .store(in: &self.cancellables)

    XCTAssertEqual(output, [])

    scheduler.advance(by: 1)
    XCTAssertEqual(output, [1_000_000_001])

    scheduler.advance(by: 1)
    XCTAssertEqual(output, [1_000_000_001, 2_000_000_001])

    scheduler.advance(by: 5)
    XCTAssertEqual(
      output,
      [
        1_000_000_001, 2_000_000_001, 3_000_000_001, 4_000_000_001, 5_000_000_001, 6_000_000_001,
        7_000_000_001,
      ]
    )
  }

  func testInterleavingTimers() {
    let scheduler = DispatchQueue.testScheduler

    var output: [Int] = []

    Publishers.MergeMany(
      Publishers.Timer(every: .seconds(2), scheduler: scheduler)
        .autoconnect()
        .handleEvents(receiveOutput: { _ in output.append(1) }),
      Publishers.Timer(every: .seconds(3), scheduler: scheduler)
        .autoconnect()
        .handleEvents(receiveOutput: { _ in output.append(2) })
    )
    .sink { _ in }
    .store(in: &self.cancellables)

    scheduler.advance(by: 1)
    XCTAssertEqual(output, [])
    scheduler.advance(by: 1)
    XCTAssertEqual(output, [1])
    scheduler.advance(by: 1)
    XCTAssertEqual(output, [1, 2])
    scheduler.advance(by: 1)
    XCTAssertEqual(output, [1, 2, 1])
    scheduler.advance(by: 1)
    XCTAssertEqual(output, [1, 2, 1])
    scheduler.advance(by: 1)
    XCTAssertEqual(output, [1, 2, 1, 1, 2])
  }

  func testTimerCancellation() {
    let scheduler = DispatchQueue.testScheduler

    var count = 0

    Publishers.Timer(every: 1, scheduler: scheduler)
      .autoconnect()
      .sink { _ in count += 1 }
      .store(in: &self.cancellables)

    scheduler.advance(by: 1)
    XCTAssertEqual(count, 1)

    self.cancellables.removeAll()
    scheduler.run()
    XCTAssertEqual(count, 1)
  }

  func testTimerCompletion() {
    let scheduler = DispatchQueue.testScheduler

    var count = 0

    Publishers.Timer(every: 1, scheduler: scheduler)
      .autoconnect()
      .prefix(3)
      .sink { _ in count += 1 }
      .store(in: &self.cancellables)

    scheduler.advance(by: 1)
    XCTAssertEqual(count, 1)

    scheduler.run()
    XCTAssertEqual(count, 3)
  }
}
#endif
