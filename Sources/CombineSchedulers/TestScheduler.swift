#if canImport(Combine)
  import Combine
  import Foundation

  /// A scheduler whose current time and execution can be controlled in a deterministic manner.
  ///
  /// This scheduler is useful for testing how the flow of time effects publishers that use
  /// asynchronous operators, such as `debounce`, `throttle`, `delay`, `timeout`, `receive(on:)`,
  /// `subscribe(on:)` and more.
  ///
  /// For example, consider the following `race` operator that runs two futures in parallel, but
  /// only emits the first one that completes:
  ///
  ///     func race<Output, Failure: Error>(
  ///       _ first: Future<Output, Failure>,
  ///       _ second: Future<Output, Failure>
  ///     ) -> AnyPublisher<Output, Failure> {
  ///       first
  ///         .merge(with: second)
  ///         .prefix(1)
  ///         .eraseToAnyPublisher()
  ///     }
  ///
  /// Although this publisher is quite simple we may still want to write some tests for it.
  ///
  /// To do this we can create a test scheduler and create two futures, one that emits after a
  /// second and one that emits after two seconds:
  ///
  ///     let scheduler = DispatchQueue.testScheduler
  ///     let first = Future<Int, Never> { callback in
  ///       scheduler.schedule(after: scheduler.now.advanced(by: 1)) { callback(.success(1)) }
  ///     }
  ///     let second = Future<Int, Never> { callback in
  ///       scheduler.schedule(after: scheduler.now.advanced(by: 2)) { callback(.success(2)) }
  ///     }
  ///
  /// And then we can race these futures and collect their emissions into an array:
  ///
  ///     var output: [Int] = []
  ///     let cancellable = race(first, second).sink { output.append($0) }
  ///
  /// And then we can deterministically move time forward in the scheduler to see how the publisher
  /// emits. We can start by moving time forward by one second:
  ///
  ///     scheduler.advance(by: 1)
  ///     XCTAssertEqual(output, [1])
  ///
  /// This proves that we get the first emission from the publisher since one second of time has
  /// passed. If we further advance by one more second we can prove that we do not get anymore
  /// emissions:
  ///
  ///     scheduler.advance(by: 1)
  ///     XCTAssertEqual(output, [1])
  ///
  /// This is a very simple example of how to control the flow of time with the test scheduler,
  /// but this technique can be used to test any publisher that involves Combine's asynchronous
  /// operations.
  ///
  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  public final class TestScheduler<SchedulerTimeType, SchedulerOptions>: Scheduler
  where SchedulerTimeType: Strideable, SchedulerTimeType.Stride: SchedulerTimeIntervalConvertible {

    private var lastSequence: UInt = 0
    public let minimumTolerance: SchedulerTimeType.Stride = .zero
    public private(set) var now: SchedulerTimeType
    private var scheduled: [(sequence: UInt, date: SchedulerTimeType, action: () -> Void)] = []

    /// Creates a test scheduler with the given date.
    ///
    /// - Parameter now: The current date of the test scheduler.
    public init(now: SchedulerTimeType) {
      self.now = now
    }

    /// Advances the scheduler by the given stride.
    ///
    /// - Parameter stride: A stride. By default this argument is `.zero`, which does not advance the
    ///   scheduler's time but does cause the scheduler to execute any units of work that are waiting
    ///   to be performed for right now.
    public func advance(by stride: SchedulerTimeType.Stride = .zero) {
      let finalDate = self.now.advanced(by: stride)

      while self.now <= finalDate {
        self.scheduled.sort { ($0.date, $0.sequence) < ($1.date, $1.sequence) }

        guard
          let nextDate = self.scheduled.first?.date,
          finalDate >= nextDate
        else {
          self.now = finalDate
          return
        }

        self.now = nextDate

        while let (_, date, action) = self.scheduled.first, date == nextDate {
          self.scheduled.removeFirst()
          action()
        }
      }
    }

    /// Runs the scheduler until it has no scheduled items left.
    ///
    /// This method is useful for proving exhaustively that your publisher eventually completes
    /// and does not run forever. For example, the following code will run an infinite loop forever
    /// because the timer never finishes:
    ///
    ///     let scheduler = DispatchQueue.testScheduler
    ///     Publishers.Timer(every: .seconds(1), scheduler: scheduler)
    ///       .autoconnect()
    ///       .sink { _ in print($0) }
    ///       .store(in: &cancellables)
    ///
    ///     scheduler.run() // Will never complete
    ///
    /// If you wanted to make sure that this publisher eventually completes you would need to
    /// chain on another operator that completes it when a certain condition is met. This can be
    /// done in many ways, such as using `prefix`:
    ///
    ///     let scheduler = DispatchQueue.testScheduler
    ///     Publishers.Timer(every: .seconds(1), scheduler: scheduler)
    ///       .autoconnect()
    ///       .prefix(3)
    ///       .sink { _ in print($0) }
    ///       .store(in: &cancellables)
    ///
    ///     scheduler.run() // Prints 3 times and completes.
    ///
    public func run() {
      while let date = self.scheduled.first?.date {
        self.advance(by: self.now.distance(to: date))
      }
    }

    public func schedule(
      after date: SchedulerTimeType,
      interval: SchedulerTimeType.Stride,
      tolerance _: SchedulerTimeType.Stride,
      options _: SchedulerOptions?,
      _ action: @escaping () -> Void
    ) -> Cancellable {
      let sequence = self.nextSequence()

      func scheduleAction(for date: SchedulerTimeType) -> () -> Void {
        return { [weak self] in
          let nextDate = date.advanced(by: interval)
          self?.scheduled.append((sequence, nextDate, scheduleAction(for: nextDate)))
          action()
        }
      }

      self.scheduled.append((sequence, date, scheduleAction(for: date)))

      return AnyCancellable { [weak self] in
        self?.scheduled.removeAll(where: { $0.sequence == sequence })
      }
    }

    public func schedule(
      after date: SchedulerTimeType,
      tolerance _: SchedulerTimeType.Stride,
      options _: SchedulerOptions?,
      _ action: @escaping () -> Void
    ) {
      self.scheduled.append((self.nextSequence(), date, action))
    }

    public func schedule(options _: SchedulerOptions?, _ action: @escaping () -> Void) {
      self.scheduled.append((self.nextSequence(), self.now, action))
    }

    private func nextSequence() -> UInt {
      self.lastSequence += 1
      return self.lastSequence
    }
  }

  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  extension Scheduler
  where
    SchedulerTimeType == DispatchQueue.SchedulerTimeType,
    SchedulerOptions == DispatchQueue.SchedulerOptions
  {
    /// A test scheduler of dispatch queues.
    public static var testScheduler: TestSchedulerOf<Self> {
      // NB: `DispatchTime(uptimeNanoseconds: 0) == .now())`. Use `1` for consistency.
      TestScheduler(now: SchedulerTimeType(DispatchTime(uptimeNanoseconds: 1)))
    }
  }

  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  extension Scheduler
  where
    SchedulerTimeType == RunLoop.SchedulerTimeType,
    SchedulerOptions == RunLoop.SchedulerOptions
  {
    /// A test scheduler of run loops.
    public static var testScheduler: TestSchedulerOf<Self> {
      TestScheduler(now: SchedulerTimeType(Date(timeIntervalSince1970: 0)))
    }
  }

  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  extension Scheduler
  where
    SchedulerTimeType == OperationQueue.SchedulerTimeType,
    SchedulerOptions == OperationQueue.SchedulerOptions
  {
    /// A test scheduler of operation queues.
    public static var testScheduler: TestSchedulerOf<Self> {
      TestScheduler(now: SchedulerTimeType(Date(timeIntervalSince1970: 0)))
    }
  }

  /// A convenience type to specify a `TestScheduler` by the scheduler it wraps rather than by the
  /// time type and options type.
  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  public typealias TestSchedulerOf<Scheduler> = TestScheduler<
    Scheduler.SchedulerTimeType, Scheduler.SchedulerOptions
  > where Scheduler: Combine.Scheduler
#endif
