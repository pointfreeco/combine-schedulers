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
            \(prefix.isEmpty ? "" : "\(prefix) - ")Unexpectedly scheduled delayed work
            """
          )
        },
        interval: { delay, interval, tolerance, options, action in
          _XCTFail(
            """
            \(prefix.isEmpty ? "" : "\(prefix) - ")Unexpectedly scheduled delayed work at an \
            interval
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
      let _XCTestObservationCenter = NSClassFromString("XCTestObservationCenter")
        as Any as? NSObjectProtocol,
      let _shared = _XCTestObservationCenter.perform(Selector(("sharedTestObservationCenter")))?
        .takeUnretainedValue(),
      let _observers = _shared.perform(Selector(("observers")))?
        .takeUnretainedValue() as? [AnyObject],
      let _observer = _observers
        .first(where: { NSStringFromClass(type(of: $0)) == "XCTestMisuseObserver" }),
      let _currentTestCase = _observer.perform(Selector(("currentTestCase")))?
        .takeUnretainedValue(),
      let _XCTIssue = NSClassFromString("XCTIssue")
        as Any as? NSObjectProtocol,
      let _alloc = _XCTIssue.perform(NSSelectorFromString("alloc"))?
        .takeUnretainedValue(),
      let _issue = _alloc
        .perform(
          Selector(("initWithType:compactDescription:")), with: 0, with: "failed - \(message)"
        )?
        .takeUnretainedValue()
    else { return }

    _ = _currentTestCase.perform(Selector(("recordIssue:")), with: _issue)
  }
#endif
