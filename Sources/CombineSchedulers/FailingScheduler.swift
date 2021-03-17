#if DEBUG && canImport(Combine)
  import Combine
  import Foundation

  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  extension Scheduler {
    public static func failing(
      _ prefix: String = "",
      minimumTolerance: @escaping () -> SchedulerTimeType.Stride,
      now: @escaping () -> SchedulerTimeType
    ) -> AnySchedulerOf<Self> {
      .init(
        minimumTolerance: minimumTolerance,
        now: {
          _XCTFail(
            """
            \(prefix.isEmpty ? "" : "\(prefix) - ")\
            A failing scheduler was asked the current time.
            """
          )
          return now()
        },
        scheduleImmediately: { options, action in
          _XCTFail(
            """
            \(prefix.isEmpty ? "" : "\(prefix) - ")\
            A failing scheduler scheduled an action to run immediately.
            """
          )
        },
        delayed: { delay, tolerance, options, action in
          _XCTFail(
            """
            \(prefix.isEmpty ? "" : "\(prefix) - ")\
            A failing scheduler scheduled an action to run later.
            """
          )
        },
        interval: { delay, interval, tolerance, options, action in
          _XCTFail(
            """
            \(prefix.isEmpty ? "" : "\(prefix) - ")\
            A failing scheduler scheduled an action to run on a timer.
            """
          )
          return AnyCancellable {}
        }
      )
    }
  }

  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  extension Scheduler
  where
    SchedulerTimeType == DispatchQueue.SchedulerTimeType,
    SchedulerOptions == DispatchQueue.SchedulerOptions
  {
    public static var failing: AnySchedulerOf<Self> {
      .failing("")
    }

    public static func failing(_ prefix: String) -> AnySchedulerOf<Self> {
      .failing(
        prefix,
        minimumTolerance: { .zero },
        now: { .init(.init(uptimeNanoseconds: 1)) }
      )
    }
  }

  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  extension Scheduler
  where
    SchedulerTimeType == RunLoop.SchedulerTimeType,
    SchedulerOptions == RunLoop.SchedulerOptions
  {
    public static var failing: AnySchedulerOf<Self> {
      .failing("")
    }

    public static func failing(_ prefix: String) -> AnySchedulerOf<Self> {
      .failing(
        prefix,
        minimumTolerance: { .zero },
        now: { .init(.init(timeIntervalSinceReferenceDate: 0)) }
      )
    }
  }

  // NB: Dynamically load XCTest to prevent leaking its symbols into our library code.
  private func _XCTFail(_ message: String, file: StaticString = #file, line: UInt = #line) {
    if
      let XCTestObservationCenter = NSClassFromString("XCTestObservationCenter")
        as Any as? NSObjectProtocol,
      let shared = XCTestObservationCenter.perform(Selector(("sharedTestObservationCenter")))?
        .takeUnretainedValue(),
      let observers = shared.perform(Selector(("observers")))?
        .takeUnretainedValue() as? [AnyObject],
      let observer =
        observers
        .first(where: { NSStringFromClass(type(of: $0)) == "XCTestMisuseObserver" }),
      let currentTestCase = observer.perform(Selector(("currentTestCase")))?
        .takeUnretainedValue(),
      let XCTIssue = NSClassFromString("XCTIssue")
        as Any as? NSObjectProtocol,
      let alloc = XCTIssue.perform(NSSelectorFromString("alloc"))?
        .takeUnretainedValue(),
      let issue =
        alloc
        .perform(
          Selector(("initWithType:compactDescription:")), with: 0, with: message
        )?
        .takeUnretainedValue()
    {
      _ = currentTestCase.perform(Selector(("recordIssue:")), with: issue)
      return
    } else if let _XCTFailureHandler = _XCTFailureHandler {
      _XCTFailureHandler(nil, true, "\(file)", line, message, nil)
    } else {
      assertionFailure(
        "Couldn't load 'XCTest'. Are you running code that calls 'XCTFail' from application code?",
        file: file,
        line: line
      )
      return
    }
  }

  private typealias XCTFailureHandler = @convention(c) (
    AnyObject?, Bool, UnsafePointer<CChar>, UInt, String, String?
  ) -> Void
  private let _XCTest = NSClassFromString("XCTest")
    .flatMap(Bundle.init(for:))
    .flatMap({ $0.executablePath })
    .flatMap({ dlopen($0, RTLD_NOW) })
  private let _XCTFailureHandler =
    _XCTest
    .flatMap { dlsym($0, "_XCTFailureHandler") }
    .map({ unsafeBitCast($0, to: XCTFailureHandler.self) })
#endif
