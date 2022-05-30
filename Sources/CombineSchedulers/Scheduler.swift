import Combine

@available(iOS 15.0, macOS 12.0, *)
extension Scheduler {
  public func sleep(
    for duration: SchedulerTimeType.Stride,
    tolerance: SchedulerTimeType.Stride,
    options: SchedulerOptions?
  ) async throws {
    try Task.checkCancellation()
    await Just(())
      .delay(for: duration, tolerance: tolerance, scheduler: self, options: options)
      .values
      .first { _ in true }
    try Task.checkCancellation()
  }
}
