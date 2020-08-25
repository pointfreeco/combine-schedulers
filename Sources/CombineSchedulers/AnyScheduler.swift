#if canImport(Combine)
  import Combine
  import Foundation

  /// A type-erasing wrapper for the `Scheduler` protocol, which can be useful for being generic over
  /// many types of schedulers without needing to actually introduce a generic to your code.
  ///
  /// This type is useful for times that you want to be able to customize the scheduler used in some
  /// code from the outside, but you don't want to introduce a generic to make it customizable. For
  /// example, suppose you have a view model `ObservableObject` that performs an API request when a
  /// method is called:
  ///
  ///     class EpisodeViewModel: ObservableObject {
  ///       @Published var episode: Episode?
  ///       private var cancellables: Set<AnyCancellable> = []
  ///
  ///       let apiClient: ApiClient
  ///
  ///       init(apiClient: ApiClient) {
  ///         self.apiClient = apiClient
  ///       }
  ///
  ///       func reloadButtonTapped() {
  ///         self.apiClient.fetchEpisode()
  ///           .receive(on: DispatchQueue.main)
  ///           .sink { self.episode = $0 }
  ///           .store(in: &self.cancellables)
  ///       }
  ///     }
  ///
  /// Notice that we are using `DispatchQueue.main` in the `reloadButtonTapped` method because the
  /// `fetchEpisode` endpoint most likely delivers its output on a background thread (as is the case
  /// with `URLSession`).
  ///
  /// This code seems innocent enough, but the presence of `.receive(on: DispatchQueue.main)` makes
  /// this code harder to test since you have to use `XCTest` expectations to explicitly wait a small
  /// amount of time for the queue to execute. This can lead to flakiness in tests and make test
  /// suites take longer to execute than necessary.
  ///
  /// One way to fix this testing problem is to use an "immediate" scheduler instead of
  /// `DispatchQueue.main`, which will cause `fetchEpisode` to deliver its output as soon as possible
  /// with no thread hops. In order to allow for this we would need to inject a scheduler into our
  /// view model so that we can control it from the outside:
  ///
  ///     class EpisodeViewModel<S: Scheduler>: ObservableObject {
  ///       @Published var episode: Episode?
  ///       private var cancellables: Set<AnyCancellable> = []
  ///
  ///       let apiClient: ApiClient
  ///       let scheduler: S
  ///
  ///       init(apiClient: ApiClient, scheduler: S) {
  ///         self.apiClient = apiClient
  ///         self.scheduler = scheduler
  ///       }
  ///
  ///       func reloadButtonTapped() {
  ///         self.apiClient.fetchEpisode()
  ///           .receive(on: self.scheduler)
  ///           .sink { self.episode = $0 }
  ///           .store(in: &self.cancellables)
  ///       }
  ///     }
  ///
  /// Now we can initialize this view model in production by using `DispatchQueue.main` and we can
  /// initialize it in tests using `DispatchQueue.immediateScheduler`. Sounds like a win!
  ///
  /// However, introducing this generic to our view model is quite heavyweight as it is loudly
  /// announcing to the outside world that this type uses a scheduler, and worse it will end up
  /// infecting any code that touches this view model that also wants to be testable. For example,
  /// any view that uses this view model will need to introduce a generic if it wants to also be able
  /// to control the scheduler, which would be useful if we wanted to write snapshot tests.
  ///
  /// Instead of introducing a generic to allow for substituting in different schedulers we can use
  /// `AnyScheduler`. It allows us to be somewhat generic in the scheduler, but without actually
  /// introducing a generic.
  ///
  /// Instead of holding a generic scheduler in our view model we can say that we only want a
  /// scheduler whose associated types match that of `DispatchQueue`:
  ///
  ///     class EpisodeViewModel: ObservableObject {
  ///       @Published var episode: Episode?
  ///
  ///       let apiClient: ApiClient
  ///       let scheduler: AnySchedulerOf<DispatchQueue>
  ///
  ///       init(apiClient: ApiClient, scheduler: AnySchedulerOf<DispatchQueue>) {
  ///         self.apiClient = apiClient
  ///         self.scheduler = scheduler
  ///       }
  ///
  ///       func reloadButtonTapped() {
  ///         self.apiClient.fetchEpisode()
  ///           .receive(on: self.scheduler)
  ///           .sink { self.episode = $0 }
  ///       }
  ///     }
  ///
  /// Then, in production we can create a view model that uses a live `DispatchQueue`, but we just
  /// have to first erase its type:
  ///
  ///     let viewModel = EpisodeViewModel(
  ///       apiClient: ...,
  ///       scheduler: DispatchQueue.main.eraseToAnyScheduler()
  ///     )
  ///
  /// And similarly in tests we can use an immediate scheduler as long as we erase its type:
  ///
  ///     let viewModel = EpisodeViewModel(
  ///       apiClient: ...,
  ///       scheduler: DispatchQueue.immediateScheduler.eraseToAnyScheduler()
  ///     )
  ///
  /// So, in general, `AnyScheduler` is great for allowing one to control what scheduler is used
  /// in classes, functions, etc. without needing to introduce a generic, which can help simplify
  /// the code and reduce implementation details from leaking out.
  ///
  @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
  public struct AnyScheduler<SchedulerTimeType, SchedulerOptions>: Scheduler
  where
    SchedulerTimeType: Strideable,
    SchedulerTimeType.Stride: SchedulerTimeIntervalConvertible
  {

    private let _minimumTolerance: () -> SchedulerTimeType.Stride
    private let _now: () -> SchedulerTimeType
    private let _scheduleAfterIntervalToleranceSchedulerOptionsAction:
      (
        SchedulerTimeType,
        SchedulerTimeType.Stride,
        SchedulerTimeType.Stride,
        SchedulerOptions?,
        @escaping () -> Void
      ) -> Cancellable
    private let _scheduleAfterToleranceSchedulerOptionsAction:
      (
        SchedulerTimeType,
        SchedulerTimeType.Stride,
        SchedulerOptions?,
        @escaping () -> Void
      ) -> Void
    private let _scheduleOptionsAction: (SchedulerOptions?, @escaping () -> Void) -> Void

    /// The minimum tolerance allowed by the scheduler.
    public var minimumTolerance: SchedulerTimeType.Stride { self._minimumTolerance() }

    /// This scheduler’s definition of the current moment in time.
    public var now: SchedulerTimeType { self._now() }

    /// Creates a type-erasing scheduler to wrap the provided endpoints.
    ///
    /// - Parameters:
    ///   - minimumTolerance: A closure that returns the scheduler's minimum tolerance.
    ///   - now: A closure that returns the scheduler's current time.
    ///   - scheduleImmediately: A closure that schedules a unit of work to be run as soon as possible.
    ///   - delayed: A closure that schedules a unit of work to be run after a delay.
    ///   - interval: A closure that schedules a unit of work to be performed on a repeating interval.
    public init(
      minimumTolerance: @escaping () -> SchedulerTimeType.Stride,
      now: @escaping () -> SchedulerTimeType,
      scheduleImmediately: @escaping (SchedulerOptions?, @escaping () -> Void) -> Void,
      delayed: @escaping (SchedulerTimeType, SchedulerTimeType.Stride, SchedulerOptions?, @escaping () -> Void) -> Void,
      interval: @escaping (SchedulerTimeType, SchedulerTimeType.Stride, SchedulerTimeType.Stride, SchedulerOptions?, @escaping () -> Void) -> Cancellable
    ) {
      self._minimumTolerance = minimumTolerance
      self._now = now
      self._scheduleOptionsAction = scheduleImmediately
      self._scheduleAfterToleranceSchedulerOptionsAction = delayed
      self._scheduleAfterIntervalToleranceSchedulerOptionsAction = interval
    }

    /// Creates a type-erasing scheduler to wrap the provided scheduler.
    ///
    /// - Parameters:
    ///   - scheduler: A scheduler to wrap with a type-eraser.
    public init<S>(
      _ scheduler: S
    )
    where
      S: Scheduler, S.SchedulerTimeType == SchedulerTimeType, S.SchedulerOptions == SchedulerOptions
    {
      self._now = { scheduler.now }
      self._minimumTolerance = { scheduler.minimumTolerance }
      self._scheduleAfterToleranceSchedulerOptionsAction = scheduler.schedule
      self._scheduleAfterIntervalToleranceSchedulerOptionsAction = scheduler.schedule
      self._scheduleOptionsAction = scheduler.schedule
    }

    /// Performs the action at some time after the specified date.
    public func schedule(
      after date: SchedulerTimeType,
      tolerance: SchedulerTimeType.Stride,
      options: SchedulerOptions?,
      _ action: @escaping () -> Void
    ) {
      self._scheduleAfterToleranceSchedulerOptionsAction(date, tolerance, options, action)
    }

    /// Performs the action at some time after the specified date, at the
    /// specified frequency, taking into account tolerance if possible.
    public func schedule(
      after date: SchedulerTimeType,
      interval: SchedulerTimeType.Stride,
      tolerance: SchedulerTimeType.Stride,
      options: SchedulerOptions?,
      _ action: @escaping () -> Void
    ) -> Cancellable {
      self._scheduleAfterIntervalToleranceSchedulerOptionsAction(
        date, interval, tolerance, options, action)
    }

    /// Performs the action at the next possible opportunity.
    public func schedule(
      options: SchedulerOptions?,
      _ action: @escaping () -> Void
    ) {
      self._scheduleOptionsAction(options, action)
    }
  }

  /// A convenience type to specify an `AnyScheduler` by the scheduler it wraps rather than by the
  /// time type and options type.
  @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
  public typealias AnySchedulerOf<Scheduler> = AnyScheduler<
    Scheduler.SchedulerTimeType, Scheduler.SchedulerOptions
  > where Scheduler: Combine.Scheduler

  @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
  extension Scheduler {
    /// Wraps this scheduler with a type eraser.
    public func eraseToAnyScheduler() -> AnyScheduler<SchedulerTimeType, SchedulerOptions> {
      AnyScheduler(self)
    }
  }
#endif
