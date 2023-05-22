#if canImport(OpenCombineShim)
  import OpenCombineShim
  import Foundation

  // NB: Soft-deprecated after 0.5.3:

  @available(iOS, deprecated: 9999.0, renamed: "UnimplementedScheduler")
  @available(macOS, deprecated: 9999.0, renamed: "UnimplementedScheduler")
  @available(tvOS, deprecated: 9999.0, renamed: "UnimplementedScheduler")
  @available(watchOS, deprecated: 9999.0, renamed: "UnimplementedScheduler")
  public typealias FailingScheduler = UnimplementedScheduler

  @available(iOS, deprecated: 9999.0, renamed: "UnimplementedSchedulerOf")
  @available(macOS, deprecated: 9999.0, renamed: "UnimplementedSchedulerOf")
  @available(tvOS, deprecated: 9999.0, renamed: "UnimplementedSchedulerOf")
  @available(watchOS, deprecated: 9999.0, renamed: "UnimplementedSchedulerOf")
  public typealias FailingSchedulerOf = UnimplementedSchedulerOf

  extension DispatchQueue {
    @available(iOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(macOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(tvOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(watchOS, deprecated: 9999.0, renamed: "unimplemented")
    public static var failing: UnimplementedSchedulerOf<DispatchQueue> { Self.unimplemented }

    @available(iOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(macOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(tvOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(watchOS, deprecated: 9999.0, renamed: "unimplemented")
    public static func failing(_ prefix: String) -> UnimplementedSchedulerOf<DispatchQueue> {
      Self.unimplemented(prefix)
    }
  }

  extension OperationQueue {
    @available(iOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(macOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(tvOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(watchOS, deprecated: 9999.0, renamed: "unimplemented")
    public static var failing: UnimplementedSchedulerOf<OperationQueue> { Self.unimplemented }

    @available(iOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(macOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(tvOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(watchOS, deprecated: 9999.0, renamed: "unimplemented")
    public static func failing(_ prefix: String) -> UnimplementedSchedulerOf<OperationQueue> {
      Self.unimplemented(prefix)
    }
  }

  extension RunLoop {
    @available(iOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(macOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(tvOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(watchOS, deprecated: 9999.0, renamed: "unimplemented")
    public static var failing: UnimplementedSchedulerOf<RunLoop> { Self.unimplemented }

    @available(iOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(macOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(tvOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(watchOS, deprecated: 9999.0, renamed: "unimplemented")
    public static func failing(_ prefix: String) -> UnimplementedSchedulerOf<RunLoop> {
      Self.unimplemented(prefix)
    }
  }

  extension AnyScheduler
  where
    SchedulerTimeType == DispatchQueue.SchedulerTimeType,
    SchedulerOptions == DispatchQueue.SchedulerOptions
  {
    @available(iOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(macOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(tvOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(watchOS, deprecated: 9999.0, renamed: "unimplemented")
    public static var failing: Self { Self.unimplemented }

    @available(iOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(macOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(tvOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(watchOS, deprecated: 9999.0, renamed: "unimplemented")
    public static func failing(_ prefix: String) -> Self { Self.unimplemented(prefix) }
  }

  extension AnyScheduler
  where
    SchedulerTimeType == OperationQueue.SchedulerTimeType,
    SchedulerOptions == OperationQueue.SchedulerOptions
  {
    @available(iOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(macOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(tvOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(watchOS, deprecated: 9999.0, renamed: "unimplemented")
    public static var failing: Self { Self.unimplemented }

    @available(iOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(macOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(tvOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(watchOS, deprecated: 9999.0, renamed: "unimplemented")
    public static func failing(_ prefix: String) -> Self { Self.unimplemented(prefix) }
  }

  extension AnyScheduler
  where
    SchedulerTimeType == RunLoop.SchedulerTimeType,
    SchedulerOptions == RunLoop.SchedulerOptions
  {
    @available(iOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(macOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(tvOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(watchOS, deprecated: 9999.0, renamed: "unimplemented")
    public static var failing: Self { Self.unimplemented }

    @available(iOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(macOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(tvOS, deprecated: 9999.0, renamed: "unimplemented")
    @available(watchOS, deprecated: 9999.0, renamed: "unimplemented")
    public static func failing(_ prefix: String) -> Self { Self.unimplemented(prefix) }
  }

  // NB: Deprecated after 0.4.1:

  extension Scheduler
  where
    SchedulerTimeType == DispatchQueue.SchedulerTimeType,
    SchedulerOptions == DispatchQueue.SchedulerOptions
  {
    @available(*, deprecated, renamed: "immediate")
    public static var immediateScheduler: ImmediateSchedulerOf<Self> {
      // NB: `DispatchTime(uptimeNanoseconds: 0) == .now())`. Use `1` for consistency.
      ImmediateScheduler(now: SchedulerTimeType(DispatchTime(uptimeNanoseconds: 1)))
    }
  }

  extension Scheduler
  where
    SchedulerTimeType == RunLoop.SchedulerTimeType,
    SchedulerOptions == RunLoop.SchedulerOptions
  {
    @available(*, deprecated, renamed: "immediate")
    public static var immediateScheduler: ImmediateSchedulerOf<Self> {
      ImmediateScheduler(now: SchedulerTimeType(Date(timeIntervalSince1970: 0)))
    }
  }

  extension Scheduler
  where
    SchedulerTimeType == OperationQueue.SchedulerTimeType,
    SchedulerOptions == OperationQueue.SchedulerOptions
  {
    @available(*, deprecated, renamed: "immediate")
    public static var immediateScheduler: ImmediateSchedulerOf<Self> {
      ImmediateScheduler(now: SchedulerTimeType(Date(timeIntervalSince1970: 0)))
    }
  }

  extension Scheduler
  where
    SchedulerTimeType == DispatchQueue.SchedulerTimeType,
    SchedulerOptions == DispatchQueue.SchedulerOptions
  {
    /// A test scheduler of dispatch queues.
    @available(*, deprecated, renamed: "test")
    public static var testScheduler: TestSchedulerOf<Self> {
      // NB: `DispatchTime(uptimeNanoseconds: 0) == .now())`. Use `1` for consistency.
      TestScheduler(now: SchedulerTimeType(DispatchTime(uptimeNanoseconds: 1)))
    }
  }

  extension Scheduler
  where
    SchedulerTimeType == OperationQueue.SchedulerTimeType,
    SchedulerOptions == OperationQueue.SchedulerOptions
  {
    /// A test scheduler of operation queues.
    @available(*, deprecated, renamed: "test")
    public static var testScheduler: TestSchedulerOf<Self> {
      TestScheduler(now: SchedulerTimeType(Date(timeIntervalSince1970: 0)))
    }
  }

  extension Scheduler
  where
    SchedulerTimeType == RunLoop.SchedulerTimeType,
    SchedulerOptions == RunLoop.SchedulerOptions
  {
    /// A test scheduler of run loops.
    @available(*, deprecated, renamed: "test")
    public static var testScheduler: TestSchedulerOf<Self> {
      TestScheduler(now: SchedulerTimeType(Date(timeIntervalSince1970: 0)))
    }
  }
#endif
