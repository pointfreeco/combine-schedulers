#if DEBUG && canImport(Combine)
  import Combine
  import Foundation

  /// A scheduler that causes the current XCTest test case to fail if it is used.
  ///
  /// This scheduler can provide an additional layer of certainty that a tested code path does not
  /// require the use of a scheduler.
  ///
  /// As a view model becomes more complex, only some of its logic may require a scheduler. When
  /// writing unit tests for any logic that does _not_ require a scheduler, one should provide a
  /// failing scheduler, instead. This documents, directly in the test, that the feature does not
  /// use a scheduler. If it did, or ever does in the future, the test will fail.
  ///
  /// For example, the following view model has a couple responsibilities:
  ///
  ///     class EpisodeViewModel: ObservableObject {
  ///       @Published var episode: Episode?
  ///
  ///       let apiClient: ApiClient
  ///       let mainQueue: AnySchedulerOf<DispatchQueue>
  ///
  ///       init(apiClient: ApiClient, mainQueue: AnySchedulerOf<DispatchQueue>) {
  ///         self.apiClient = apiClient
  ///         self.mainQueue = mainQueue
  ///       }
  ///
  ///       func reloadButtonTapped() {
  ///         self.apiClient.fetchEpisode()
  ///           .receive(on: self.mainQueue)
  ///           .assign(to: &self.$episode)
  ///       }
  ///
  ///       func favoriteButtonTapped() {
  ///         self.episode?.isFavorite.toggle()
  ///       }
  ///     }
  ///
  ///   * It lets the user tap a button to refresh some episode data
  ///   * It lets the user toggle if the episode is one of their favorites
  ///
  /// The API client delivers the episode on a background queue, so the view model must receive it
  /// on its main queue before mutating its state.
  ///
  /// Tapping the reload button, however, involves no scheduling. This means that a test can be
  /// written with a failing scheduler:
  ///
  ///     func testFavoriteButton() {
  ///       let viewModel = EpisodeViewModel(
  ///         apiClient: .mock,
  ///         mainQueue: .failing
  ///       )
  ///       viewModel.episode = .mock
  ///
  ///       viewModel.favoriteButtonTapped()
  ///       XCTAssert(viewModel.episode?.isFavorite == true)
  ///
  ///       viewModel.favoriteButtonTapped()
  ///       XCTAssert(viewModel.episode?.isFavorite == false)
  ///     }
  ///
  /// With `.failing`, this test pretty strongly declares that favoriting an episode does not need
  /// a scheduler to do the job, which means it is reasonable to assume that the feature is simple
  /// and does not involve any asynchrony.
  ///
  /// In the future, should favoriting an episode fire off an API request that involves a scheduler,
  /// this test will begin to fail, which is a good thing! This will force us to address the
  /// complexity that was introduced. Had we used any other scheduler, it would quietly receive this
  /// additional work and the test would continue to pass.
  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  public struct FailingScheduler<SchedulerTimeType, SchedulerOptions>: Scheduler
  where
    SchedulerTimeType: Strideable,
    SchedulerTimeType.Stride: SchedulerTimeIntervalConvertible
  {

    public var minimumTolerance: SchedulerTimeType.Stride {
      _XCTFail(
        """
        \(self.prefix.isEmpty ? "" : "\(self.prefix) - ")\
        A failing scheduler was asked its minimum tolerance.
        """
      )
      return self._minimumTolerance
    }

    public var now: SchedulerTimeType {
      _XCTFail(
        """
        \(self.prefix.isEmpty ? "" : "\(self.prefix) - ")\
        A failing scheduler was asked the current time.
        """
      )
      return self._now
    }

    public let prefix: String
    private let _minimumTolerance: SchedulerTimeType.Stride = .zero
    private let _now: SchedulerTimeType

    /// Creates a failing test scheduler with the given date.
    ///
    /// - Parameters:
    ///   - prefix: A string that identifies this scheduler and will prefix all failure messages.
    ///   - now: now: The current date of the failing scheduler.
    public init(_ prefix: String = "", now: SchedulerTimeType) {
      self._now = now
      self.prefix = prefix
    }

    public func schedule(options _: SchedulerOptions?, _ action: () -> Void) {
      _XCTFail(
        """
        \(self.prefix.isEmpty ? "" : "\(self.prefix) - ")\
        A failing scheduler scheduled an action to run immediately.
        """
      )
    }

    public func schedule(
      after _: SchedulerTimeType,
      tolerance _: SchedulerTimeType.Stride,
      options _: SchedulerOptions?,
      _ action: () -> Void
    ) {
      _XCTFail(
        """
        \(self.prefix.isEmpty ? "" : "\(self.prefix) - ")\
        A failing scheduler scheduled an action to run later.
        """
      )
    }

    public func schedule(
      after _: SchedulerTimeType,
      interval _: SchedulerTimeType.Stride,
      tolerance _: SchedulerTimeType.Stride,
      options _: SchedulerOptions?,
      _ action: () -> Void
    ) -> Cancellable {
      _XCTFail(
        """
        \(self.prefix.isEmpty ? "" : "\(self.prefix) - ")\
        A failing scheduler scheduled an action to run on a timer.
        """
      )
      return AnyCancellable {}
    }
  }

  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  extension AnyScheduler
  where
    SchedulerTimeType == DispatchQueue.SchedulerTimeType,
    SchedulerOptions == DispatchQueue.SchedulerOptions
  {
    public static var failing: Self {
      .failing("")
    }

    public static func failing(_ prefix: String) -> Self {
      DispatchQueue.failing(prefix).eraseToAnyScheduler()
    }
  }

  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  extension AnyScheduler
  where
    SchedulerTimeType == RunLoop.SchedulerTimeType,
    SchedulerOptions == RunLoop.SchedulerOptions
  {
    public static var failing: Self {
      .failing("")
    }

    public static func failing(_ prefix: String) -> Self {
      RunLoop.failing(prefix).eraseToAnyScheduler()
    }
  }

  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  extension AnyScheduler
  where
    SchedulerTimeType == OperationQueue.SchedulerTimeType,
    SchedulerOptions == OperationQueue.SchedulerOptions
  {
    public static var failing: Self {
      .failing("")
    }

    public static func failing(_ prefix: String) -> Self {
      OperationQueue.failing(prefix).eraseToAnyScheduler()
    }
  }

  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension Scheduler {
    public static func failing(
      _ prefix: String = "", now: SchedulerTimeType
    ) -> FailingSchedulerOf<Self> {
      .init(prefix, now: now)
    }
  }

  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension DispatchQueue {
    public static func failing(_ prefix: String = "") -> FailingSchedulerOf<DispatchQueue> {
      .init(prefix, now: .init(.init(uptimeNanoseconds: 1)))
    }
  }

  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension OperationQueue {
    public static func failing(_ prefix: String = "") -> FailingSchedulerOf<OperationQueue> {
      .init(prefix, now: .init(.init(timeIntervalSince1970: 0)))
    }
  }

  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension RunLoop {
    public static func failing(_ prefix: String = "") -> FailingSchedulerOf<RunLoop> {
      .init(prefix, now: .init(.init(timeIntervalSince1970: 0)))
    }
  }

  /// A convenience type to specify a `FailingScheduler` by the scheduler it wraps rather than by
  /// the time type and options type.
  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  public typealias FailingSchedulerOf<Scheduler> = FailingScheduler<
    Scheduler.SchedulerTimeType, Scheduler.SchedulerOptions
  > where Scheduler: Combine.Scheduler

  // NB: Dynamically load XCTest to prevent leaking its symbols into our library code.
  private func _XCTFail(_ message: String, file: StaticString = #file, line: UInt = #line) {
    // Xcode 12: Record XCTIssue
    if
      let XCTestObservationCenter = NSClassFromString("XCTestObservationCenter")
        as Any as? NSObjectProtocol,
      let shared = XCTestObservationCenter.perform(Selector(("sharedTestObservationCenter")))?
        .takeUnretainedValue(),
      let observers = shared.perform(Selector(("observers")))?
        .takeUnretainedValue() as? [AnyObject],
      let observer =
        observers
        .first(where: { NSStringFromClass(type(of: $0)) == "XCTestMisuseObserver" }),
      let currentTestCase = observer.perform(Selector(("currentTestCase")))?
        .takeUnretainedValue(),
      let XCTIssue = NSClassFromString("XCTIssue")
        as Any as? NSObjectProtocol,
      let alloc = XCTIssue.perform(NSSelectorFromString("alloc"))?
        .takeUnretainedValue(),
      let issue =
        alloc
        .perform(
          Selector(("initWithType:compactDescription:")), with: 0, with: message
        )?
        .takeUnretainedValue()
    {
      _ = currentTestCase.perform(Selector(("recordIssue:")), with: issue)
      return
    }

    // Xcode <12: Call XCTFail
    if let _XCTFailureHandler = _XCTFailureHandler {
      _XCTFailureHandler(nil, true, "\(file)", line, message, nil)
      return
    }

    assertionFailure(
      "Couldn't load 'XCTest'. Are you running code that calls 'XCTFail' from application code?",
      file: file,
      line: line
    )
    return
  }

  private typealias XCTFailureHandler = @convention(c) (
    AnyObject?, Bool, UnsafePointer<CChar>, UInt, String, String?
  ) -> Void
  private let _XCTest = NSClassFromString("XCTest")
    .flatMap(Bundle.init(for:))
    .flatMap({ $0.executablePath })
    .flatMap({ dlopen($0, RTLD_NOW) })
  private let _XCTFailureHandler =
    _XCTest
    .flatMap { dlsym($0, "_XCTFailureHandler") }
    .map({ unsafeBitCast($0, to: XCTFailureHandler.self) })
#endif
