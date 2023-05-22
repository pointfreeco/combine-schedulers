#if canImport(OpenCombineShim)
  import OpenCombineShim

  extension Scheduler {
    /// Suspends the current task for at least the given duration.
    ///
    /// If the task is cancelled before the time ends, this function throws `CancellationError`.
    ///
    /// This function doesn't block the scheduler.
    ///
    /// ```
    /// try await in scheduler.sleep(for: .seconds(1))
    /// ```
    ///
    /// - Parameters:
    ///   - duration: The time interval on which to sleep between yielding.
    ///   - tolerance: The allowed timing variance when emitting events. Defaults to `zero`.
    ///   - options: Scheduler options passed to the timer. Defaults to `nil`.
    public func sleep(
      for duration: SchedulerTimeType.Stride,
      tolerance: SchedulerTimeType.Stride = .zero,
      options: SchedulerOptions? = nil
    ) async throws {
      try Task.checkCancellation()
      _ =
        await self
        .timer(interval: duration, tolerance: tolerance, options: options)
        .first { _ in true }
      try Task.checkCancellation()
    }

    /// Suspend task execution until a given deadline within a tolerance.
    ///
    /// If the task is cancelled before the time ends, this function throws `CancellationError`.
    ///
    /// This function doesn't block the scheduler.
    ///
    /// ```
    /// try await in scheduler.sleep(until: scheduler.now + .seconds(1))
    /// ```

    /// - Parameters:
    ///   - deadline: An instant of time to suspend until.
    ///   - tolerance: The allowed timing variance when emitting events. Defaults to `zero`.
    ///   - options: Scheduler options passed to the timer. Defaults to `nil`.
    public func sleep(
      until deadline: SchedulerTimeType,
      tolerance: SchedulerTimeType.Stride = .zero,
      options: SchedulerOptions? = nil
    ) async throws {
      try await self.sleep(
        for: self.now.distance(to: deadline),
        tolerance: tolerance,
        options: options
      )
    }

    /// Returns a stream that repeatedly yields the current time of the scheduler on a given interval.
    ///
    /// If the task is cancelled, the sequence will terminate.
    ///
    /// ```
    /// for await instant in scheduler.timer(interval: .seconds(1)) {
    ///   print("now:", instant)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - interval: The time interval on which to sleep between yielding the current instant in
    ///     time. For example, a value of `0.5` yields an instant approximately every half-second.
    ///   - tolerance: The allowed timing variance when emitting events. Defaults to `zero`.
    ///   - options: Scheduler options passed to the timer. Defaults to `nil`.
    /// - Returns: A stream that repeatedly yields the current time.
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
        continuation.onTermination =
          { _ in
            cancellable.cancel()
          }
          // NB: This explicit cast is needed to work around a compiler bug in Swift 5.5.2
          as @Sendable (AsyncStream<SchedulerTimeType>.Continuation.Termination) -> Void
      }
    }

    /// Measure the elapsed time to execute a closure.
    ///
    /// ```
    /// let elapsed = scheduler.measure {
    ///   someWork()
    /// }
    /// ```
    ///
    /// - Parameter work: A closure to execute.
    /// - Returns: The amount of time it took to execute the closure.
    public func measure(_ work: () throws -> Void) rethrows -> SchedulerTimeType.Stride {
      let start = self.now
      try work()
      return start.distance(to: self.now)
    }
  }
#endif
