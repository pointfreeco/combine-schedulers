#if DEBUG
  import Combine
  import Foundation

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
  private func _XCTFail(_ message: String) {
    guard
      let XCTestObservationCenter = NSClassFromString("XCTestObservationCenter")
        as Any as? NSObjectProtocol,
      let shared = XCTestObservationCenter.perform(Selector(("sharedTestObservationCenter")))?
        .takeUnretainedValue(),
      let observers = shared.perform(Selector(("observers")))?
        .takeUnretainedValue() as? [AnyObject],
      let observer = observers
        .first(where: { NSStringFromClass(type(of: $0)) == "XCTestMisuseObserver" }),
      let currentTestCase = observer.perform(Selector(("currentTestCase")))?
        .takeUnretainedValue(),
      let XCTIssue = NSClassFromString("XCTIssue")
        as Any as? NSObjectProtocol,
      let alloc = XCTIssue.perform(NSSelectorFromString("alloc"))?
        .takeUnretainedValue(),
      let issue = alloc
        .perform(
          Selector(("initWithType:compactDescription:")), with: 0, with: message
        )?
        .takeUnretainedValue()
    else {
      // - assertionFailure?
      // - fall back to TCA-based XCTFail?
      return
    }

    _ = currentTestCase.perform(Selector(("recordIssue:")), with: issue)
  }
#endif
