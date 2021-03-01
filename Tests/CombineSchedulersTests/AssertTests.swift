import Combine
import CombineSchedulers

extension Publisher {

  func assert(
    _ steps: Step<Output, Failure>...,
    receiveCompletion completion: Subscribers.Completion<Failure> = .finished,
    file: StaticString = #file,
    line: UInt = #line
  )
  where Output: Equatable, Failure: Equatable {
    self.assert(steps, receiveCompletion: completion, file: file, line: line)
  }

  func assert(
    _ steps: [Step<Output, Failure>],
    receiveCompletion completion: Subscribers.Completion<Failure> = .finished,
    file: StaticString = #file,
    line: UInt = #line
  )
  where Output: Equatable, Failure: Equatable {
    var receivedValues: [Output] = []
    var receivedCompletion: Subscribers.Completion<Failure>?
    let cancellable = self.sink(
      receiveCompletion: { receivedCompletion = $0 },
      receiveValue: { receivedValues.append($0) }
    )
    for step in steps {
      switch step {
      case let .do(action, file, line):
        XCTAssertNoThrow(try action(), file: file, line: line)
      case let .receiveValue(value, file, line):
        guard !receivedValues.isEmpty else {
          XCTFail("Expected a value but received none", file: file, line: line)
          return
        }
        XCTAssertEqual(value, receivedValues.removeFirst(), file: file, line: line)
      }
    }
    if let receivedCompletion = receivedCompletion {
      XCTAssertEqual(completion, receivedCompletion, file: file, line: line)
    } else {
      XCTFail("Expected a completion but received none", file: file, line: line)
    }
    _ = cancellable
  }

}

enum Step<Output, Failure> where Failure: Error {
  case `do`(() throws -> Void, file: StaticString = #file, line: UInt = #line)
  case receiveValue(Output, file: StaticString = #file, line: UInt = #line)
}

import XCTest

class AssertTests: XCTestCase {
  func testAssert() {
    Just(5).assert(
      .receiveValue(5),
      receiveCompletion: .finished
    )

    Just(5).assert(.receiveValue(5))

    let error = NSError(domain: "co.pointfree", code: -1, userInfo: nil)
    Fail(outputType: Int.self, failure: error)
      .assert(
        receiveCompletion: .failure(error)
      )

    let scheduler = DispatchQueue.testScheduler
    Just(5)
      .delay(for: 1, scheduler: scheduler)
      .assert(
        .do { scheduler.advance(by: 1) },
        .receiveValue(5)
      )

//      .assert(withCompletion: .failure(error)) {
//        ReceiveValue(1)
//
//        scheduler.advance(by: 1)
//
//        ReceiveValue(1)
//      }
    // .assert { }
    //
    // .assert {
    // }
    //
    // receiveCompletion: .failure(error)
    //
    // .receiveCompletion(.failure(error))

    Publishers.Timer(every: .seconds(1), scheduler: scheduler)
      .autoconnect()
      .prefix(5)
      .scan(0) { accum, _ in accum + 1 }
      .assert(
        .do { scheduler.advance(by: 1) },
        .receiveValue(1),

        .do { scheduler.advance(by: 1) },
        .receiveValue(2),

        .do { scheduler.advance(by: 1) },
        .receiveValue(3),

//        .do { scheduler.advance(by: 1) },
//        .receiveValue(4),

        .do { scheduler.advance(by: 1) },
        .receiveValue(5)
      )
  }
}
