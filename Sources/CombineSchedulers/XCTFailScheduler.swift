#if DEBUG
  import Combine

  extension Scheduler {
    public static func failing(
      _ prefix: String = "",
      minimumTolerance: @escaping () -> SchedulerTimeType.Stride,
      now: @escaping () -> SchedulerTimeType
    ) -> AnySchedulerOf<Self> {
      .init(
        minimumTolerance: {
          _XCTFail("\(prefix.isEmpty ? "" : "\(prefix) - ")Unexpectedly asked its tolerance")
          return minimumTolerance()
        },
        now: {
          _XCTFail("\(prefix.isEmpty ? "" : "\(prefix) - ")Unexpectedly asked its current time")
          return now()
        },
        scheduleImmediately: { options, action in
          _XCTFail("\(prefix.isEmpty ? "" : "\(prefix) - ")Unexpectedly scheduled immediate work")
        },
        delayed: { delay, tolerance, options, action in
          _XCTFail(
            """
            \(prefix.isEmpty ? "" : "\(prefix) - ")Unexpectedly scheduled work delayed by \(delay)
            """
          )
        },
        interval: { delay, interval, tolerance, options, action in
          _XCTFail(
            """
            \(prefix.isEmpty ? "" : "\(prefix) - ")Unexpectedly scheduled work \
            \(interval == .zero ? "" : "delayed by \(delay) ")every \(interval)
            """
          )
          return AnyCancellable {}
        }
      )
    }
  }

  extension Scheduler
  where
    SchedulerTimeType == DispatchQueue.SchedulerTimeType,
    SchedulerOptions == DispatchQueue.SchedulerOptions
  {
    static var failing: AnySchedulerOf<Self> {
      .failing("")
    }

    static func failing(_ prefix: String) -> AnySchedulerOf<Self> {
      .failing(
        prefix,
        minimumTolerance: { .zero },
        now: { .init(.init(uptimeNanoseconds: 1)) }
      )
    }
  }

  extension Scheduler
  where
    SchedulerTimeType == RunLoop.SchedulerTimeType,
    SchedulerOptions == RunLoop.SchedulerOptions
  {
    static var failing: AnySchedulerOf<Self> {
      .failing("")
    }

    static func failing(_ prefix: String) -> AnySchedulerOf<Self> {
      .failing(
        minimumTolerance: { .zero },
        now: { .init(.init(timeIntervalSinceReferenceDate: 0)) }
      )
    }
  }

  // NB: Dynamically load XCTest to prevent leaking its symbols into our library code.
  private func _XCTFail(_ message: String = "", file: StaticString = #file, line: UInt = #line) {
    guard
      let _XCTFailureHandler = _XCTFailureHandler,
      let _XCTCurrentTestCase = _XCTCurrentTestCase
    else {
      assertionFailure(
        """
        Couldn't load XCTest. Are you using a test store in application code?"
        """,
        file: file,
        line: line
      )
      return
    }
    _XCTFailureHandler(_XCTCurrentTestCase(), true, "\(file)", line, message, nil)
  }

  private typealias XCTCurrentTestCase = @convention(c) () -> AnyObject
  private typealias XCTFailureHandler = @convention(c) (
    AnyObject, Bool, UnsafePointer<CChar>, UInt, String, String?
  ) -> Void

  private let _XCTest = NSClassFromString("XCTest")
    .flatMap(Bundle.init(for:))
    .flatMap { $0.executablePath }
    .flatMap { dlopen($0, RTLD_NOW) }

  private let _XCTFailureHandler =
    _XCTest
    .flatMap { dlsym($0, "_XCTFailureHandler") }
    .map { unsafeBitCast($0, to: XCTFailureHandler.self) }

  private let _XCTCurrentTestCase =
    _XCTest
    .flatMap { dlsym($0, "_XCTCurrentTestCase") }
    .map { unsafeBitCast($0, to: XCTCurrentTestCase.self) }
#endif
