import Combine

extension Scheduler {
  public func sleep(
    for duration: SchedulerTimeType.Stride,
    tolerance: SchedulerTimeType.Stride = .zero,
    options: SchedulerOptions? = nil
  ) async throws {
    try Task.checkCancellation()
    _ = await self
      .timer(interval: duration, tolerance: tolerance, options: options)
      .first { _ in true }
    try Task.checkCancellation()
  }

  public func timer(
    interval: SchedulerTimeType.Stride,
    tolerance: SchedulerTimeType.Stride = .zero,
    options: SchedulerOptions? = nil
  ) -> AsyncStream<SchedulerTimeType> {
    .init { continuation in
      let cancellable = self.schedule(
        after: self.now.advanced(by: interval),
        interval: interval,
        tolerance: tolerance,
        options: options
      ) {
        continuation.yield(self.now)
      }
      continuation.onTermination = { _ in
        cancellable.cancel()
      }
    }
  }
}
