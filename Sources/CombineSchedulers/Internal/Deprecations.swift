#if canImport(Combine)
  import Combine
  import Foundation

  // To later deprecate:

  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension Scheduler
  where
    SchedulerTimeType == DispatchQueue.SchedulerTimeType,
    SchedulerOptions == DispatchQueue.SchedulerOptions
  {
//    @available(*, deprecated, renamed: "immediate")
    public static var immediateScheduler: ImmediateSchedulerOf<Self> {
      // NB: `DispatchTime(uptimeNanoseconds: 0) == .now())`. Use `1` for consistency.
      ImmediateScheduler(now: SchedulerTimeType(DispatchTime(uptimeNanoseconds: 1)))
    }
  }

  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension Scheduler
  where
    SchedulerTimeType == RunLoop.SchedulerTimeType,
    SchedulerOptions == RunLoop.SchedulerOptions
  {
//    @available(*, deprecated, renamed: "immediate")
    public static var immediateScheduler: ImmediateSchedulerOf<Self> {
      ImmediateScheduler(now: SchedulerTimeType(Date(timeIntervalSince1970: 0)))
    }
  }

  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension Scheduler
  where
    SchedulerTimeType == OperationQueue.SchedulerTimeType,
    SchedulerOptions == OperationQueue.SchedulerOptions
  {
//    @available(*, deprecated, renamed: "immediate")
    public static var immediateScheduler: ImmediateSchedulerOf<Self> {
      ImmediateScheduler(now: SchedulerTimeType(Date(timeIntervalSince1970: 0)))
    }
  }

  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  extension Scheduler
  where
    SchedulerTimeType == DispatchQueue.SchedulerTimeType,
    SchedulerOptions == DispatchQueue.SchedulerOptions
  {
//    @available(*, deprecated, renamed: "test")
    /// A test scheduler of dispatch queues.
    public static var testScheduler: TestSchedulerOf<Self> {
      // NB: `DispatchTime(uptimeNanoseconds: 0) == .now())`. Use `1` for consistency.
      TestScheduler(now: SchedulerTimeType(DispatchTime(uptimeNanoseconds: 1)))
    }
  }

  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  extension Scheduler
  where
    SchedulerTimeType == OperationQueue.SchedulerTimeType,
    SchedulerOptions == OperationQueue.SchedulerOptions
  {
//    @available(*, deprecated, renamed: "test")
    /// A test scheduler of operation queues.
    public static var testScheduler: TestSchedulerOf<Self> {
      TestScheduler(now: SchedulerTimeType(Date(timeIntervalSince1970: 0)))
    }
  }

  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  extension Scheduler
  where
    SchedulerTimeType == RunLoop.SchedulerTimeType,
    SchedulerOptions == RunLoop.SchedulerOptions
  {
//    @available(*, deprecated, renamed: "test")
    /// A test scheduler of run loops.
    public static var testScheduler: TestSchedulerOf<Self> {
      TestScheduler(now: SchedulerTimeType(Date(timeIntervalSince1970: 0)))
    }
  }
#endif
