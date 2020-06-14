import Combine
import Foundation

/// A scheduler for performing synchronous actions.
///
/// You can only use this scheduler for immediate actions. If you attempt to schedule actions
/// after a specific date, this scheduler ignores the date and performs them immediately.
///
/// This scheduler can be useful for writing tests against publishers that use `receive(on:)`
/// or `subscribe(on:)` because it will force the publisher to emit immediately, rather than
/// needing to wait for a thread hop using `XCTestExpectation`.
public struct ImmediateScheduler<SchedulerTimeType, SchedulerOptions>: Scheduler
where
  SchedulerTimeType: Strideable,
  SchedulerTimeType.Stride: SchedulerTimeIntervalConvertible
{

  public let minimumTolerance: SchedulerTimeType.Stride = .zero
  public let now: SchedulerTimeType

  /// Creates an immediate test scheduler with the given date.
  ///
  /// - Parameter now: The current date of the test scheduler.
  public init(now: SchedulerTimeType) {
    self.now = now
  }

  public func schedule(options _: SchedulerOptions?, _ action: () -> Void) {
    action()
  }

  public func schedule(
    after _: SchedulerTimeType,
    interval _: SchedulerTimeType.Stride,
    tolerance _: SchedulerTimeType.Stride,
    options _: SchedulerOptions?,
    _ action: () -> Void
  ) -> Cancellable {
    action()
    return AnyCancellable {}
  }

  public func schedule(
    after _: SchedulerTimeType,
    tolerance _: SchedulerTimeType.Stride,
    options _: SchedulerOptions?,
    _ action: () -> Void
  ) {
    action()
  }
}

extension Scheduler
where
  SchedulerTimeType == DispatchQueue.SchedulerTimeType,
  SchedulerOptions == DispatchQueue.SchedulerOptions
{
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
  public static var immediateScheduler: ImmediateSchedulerOf<Self> {
    ImmediateScheduler(now: SchedulerTimeType(Date(timeIntervalSince1970: 0)))
  }
}

extension Scheduler
where
  SchedulerTimeType == OperationQueue.SchedulerTimeType,
  SchedulerOptions == OperationQueue.SchedulerOptions
{
  public static var immediateScheduler: ImmediateSchedulerOf<Self> {
    ImmediateScheduler(now: SchedulerTimeType(Date(timeIntervalSince1970: 0)))
  }
}

/// A convenience type to specify an `ImmediateTestScheduler` by the scheduler it wraps rather than
/// by the time type and options type.
public typealias ImmediateSchedulerOf<Scheduler> = ImmediateScheduler<
  Scheduler.SchedulerTimeType, Scheduler.SchedulerOptions
> where Scheduler: Combine.Scheduler
