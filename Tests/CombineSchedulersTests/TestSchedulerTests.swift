import Combine
import CombineSchedulers
import XCTest

final class CombineSchedulerTests: XCTestCase {
  var cancellables: Set<AnyCancellable> = []

  func testAdvance() {
    let scheduler = DispatchQueue.test

    var value: Int?
    Just(1)
      .delay(for: 1, scheduler: scheduler)
      .sink { value = $0 }
      .store(in: &self.cancellables)

    XCTAssertEqual(value, nil)

    scheduler.advance(by: .milliseconds(250))

    XCTAssertEqual(value, nil)

    scheduler.advance(by: .milliseconds(250))

    XCTAssertEqual(value, nil)

    scheduler.advance(by: .milliseconds(250))

    XCTAssertEqual(value, nil)

    scheduler.advance(by: .milliseconds(250))

    XCTAssertEqual(value, 1)
  }

  func testRunScheduler() {
    let scheduler = DispatchQueue.test

    var value: Int?
    Just(1)
      .delay(for: 1_000_000_000, scheduler: scheduler)
      .sink { value = $0 }
      .store(in: &self.cancellables)

    XCTAssertEqual(value, nil)

    scheduler.advance(by: 1_000_000)

    XCTAssertEqual(value, nil)

    scheduler.run()

    XCTAssertEqual(value, 1)
  }

  func testDelay0Advance() {
    let scheduler = DispatchQueue.test

    var value: Int?
    Just(1)
      .delay(for: 0, scheduler: scheduler)
      .sink { value = $0 }
      .store(in: &self.cancellables)

    XCTAssertEqual(value, nil)

    scheduler.advance()

    XCTAssertEqual(value, 1)
  }

  func testSubscribeOnAdvance() {
    let scheduler = DispatchQueue.test

    var value: Int?
    Just(1)
      .subscribe(on: scheduler)
      .sink { value = $0 }
      .store(in: &self.cancellables)

    XCTAssertEqual(value, nil)

    scheduler.advance()

    XCTAssertEqual(value, 1)
  }

  func testReceiveOnAdvance() {
    let scheduler = DispatchQueue.test

    var value: Int?
    Just(1)
      .receive(on: scheduler)
      .sink { value = $0 }
      .store(in: &self.cancellables)

    XCTAssertEqual(value, nil)

    scheduler.advance()

    XCTAssertEqual(value, 1)
  }

  func testDispatchQueueDefaults() {
    let scheduler = DispatchQueue.test
    scheduler.advance(by: .nanoseconds(0))

    XCTAssertEqual(
      scheduler.now,
      .init(DispatchTime(uptimeNanoseconds: 1)),
      """
      Default of dispatchQueue.now should not be 0 because that has special meaning in DispatchTime's \
      initializer and causes it to default to DispatchTime.now().
      """
    )
  }

  func testTwoIntervalOrdering() {
    let testScheduler = DispatchQueue.test

    var values: [Int] = []

    testScheduler.schedule(after: testScheduler.now, interval: 2) { values.append(1) }
      .store(in: &self.cancellables)

    testScheduler.schedule(after: testScheduler.now, interval: 1) { values.append(42) }
      .store(in: &self.cancellables)

    XCTAssertEqual(values, [])
    testScheduler.advance()
    XCTAssertEqual(values, [1, 42])
    testScheduler.advance(by: 2)
    XCTAssertEqual(values, [1, 42, 42, 1, 42])
  }
}
