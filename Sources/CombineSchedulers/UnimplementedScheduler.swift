#if canImport(Combine)
  import Combine
  import Foundation
  import XCTestDynamicOverlay

  /// A scheduler that causes the current XCTest test case to fail if it is used.
  ///
  /// This scheduler can provide an additional layer of certainty that a tested code path does not
  /// require the use of a scheduler.
  ///
  /// As a view model becomes more complex, only some of its logic may require a scheduler. When
  /// writing unit tests for any logic that does _not_ require a scheduler, one should provide an
  /// unimplemented scheduler, instead. This documents, directly in the test, that the feature does
  /// not use a scheduler. If it did, or ever does in the future, the test will fail.
  ///
  /// For example, the following view model has a couple responsibilities:
  ///
  /// ```swift
  /// class EpisodeViewModel: ObservableObject {
  ///   @Published var episode: Episode?
  ///
  ///   let apiClient: ApiClient
  ///   let mainQueue: AnySchedulerOf<DispatchQueue>
  ///
  ///   init(apiClient: ApiClient, mainQueue: AnySchedulerOf<DispatchQueue>) {
  ///     self.apiClient = apiClient
  ///     self.mainQueue = mainQueue
  ///   }
  ///
  ///   func reloadButtonTapped() {
  ///     self.apiClient.fetchEpisode()
  ///       .receive(on: self.mainQueue)
  ///       .assign(to: &self.$episode)
  ///   }
  ///
  ///   func favoriteButtonTapped() {
  ///     self.episode?.isFavorite.toggle()
  ///   }
  /// }
  /// ```
  ///
  ///   * It lets the user tap a button to refresh some episode data
  ///   * It lets the user toggle if the episode is one of their favorites
  ///
  /// The API client delivers the episode on a background queue, so the view model must receive it
  /// on its main queue before mutating its state.
  ///
  /// Tapping the favorite button, however, involves no scheduling. This means that a test can be
  /// written with an unimplemented scheduler:
  ///
  /// ```swift
  /// func testFavoriteButton() {
  ///   let viewModel = EpisodeViewModel(
  ///     apiClient: .mock,
  ///     mainQueue: .unimplemented
  ///   )
  ///   viewModel.episode = .mock
  ///
  ///   viewModel.favoriteButtonTapped()
  ///   XCTAssert(viewModel.episode?.isFavorite == true)
  ///
  ///   viewModel.favoriteButtonTapped()
  ///   XCTAssert(viewModel.episode?.isFavorite == false)
  /// }
  /// ```
  ///
  /// With `.unimplemented`, this test pretty strongly declares that favoriting an episode does not
  /// need a scheduler to do the job, which means it is reasonable to assume that the feature is
  /// simple and does not involve any asynchrony.
  ///
  /// In the future, should favoriting an episode fire off an API request that involves a scheduler,
  /// this test will begin to fail, which is a good thing! This will force us to address the
  /// complexity that was introduced. Had we used any other scheduler, it would quietly receive this
  /// additional work and the test would continue to pass.
  public struct UnimplementedScheduler<S: Scheduler>: Scheduler {
    public typealias SchedulerTimeType = S.SchedulerTimeType
    public typealias SchedulerOptions = S.SchedulerOptions

    public var minimumTolerance: SchedulerTimeType.Stride {
      XCTFail(
        """
        \(self.prefix.isEmpty ? "" : "\(self.prefix) - ")\
        An unimplemented scheduler was asked its minimum tolerance.
        """
      )
      return self._minimumTolerance
    }

    public var now: SchedulerTimeType {
      XCTFail(
        """
        \(self.prefix.isEmpty ? "" : "\(self.prefix) - ")\
        An unimplemented scheduler was asked the current time.
        """
      )
      return self._now
    }

    public let prefix: String
    private let _minimumTolerance: SchedulerTimeType.Stride = .zero
    private let _now: SchedulerTimeType

    /// Creates an unimplemented scheduler with the given date.
    ///
    /// - Parameters:
    ///   - prefix: A string that identifies this scheduler and will prefix all failure messages.
    ///   - now: now: The current date of the unimplemented scheduler.
    public init(_ prefix: String = "", now: SchedulerTimeType) {
      self._now = now
      self.prefix = prefix
    }

    public func schedule(options _: SchedulerOptions?, _ action: () -> Void) {
      XCTFail(
        """
        \(self.prefix.isEmpty ? "" : "\(self.prefix) - ")\
        An unimplemented scheduler scheduled an action to run immediately.
        """
      )
      action()
    }

    public func schedule(
      after _: SchedulerTimeType,
      tolerance _: SchedulerTimeType.Stride,
      options _: SchedulerOptions?,
      _ action: () -> Void
    ) {
      XCTFail(
        """
        \(self.prefix.isEmpty ? "" : "\(self.prefix) - ")\
        An unimplemented scheduler scheduled an action to run later.
        """
      )
      action()
    }

    public func schedule(
      after _: SchedulerTimeType,
      interval _: SchedulerTimeType.Stride,
      tolerance _: SchedulerTimeType.Stride,
      options _: SchedulerOptions?,
      _ action: () -> Void
    ) -> Cancellable {
      XCTFail(
        """
        \(self.prefix.isEmpty ? "" : "\(self.prefix) - ")\
        An unimplemented scheduler scheduled an action to run on a timer.
        """
      )
      action()
      return AnyCancellable {}
    }
  }

  extension UnimplementedScheduler: Sendable
  where SchedulerTimeType: Sendable, SchedulerTimeType.Stride: Sendable {}

  extension DispatchQueue {
    /// An unimplemented scheduler that can substitute itself for a dispatch queue.
    public static var unimplemented: UnimplementedSchedulerOf<DispatchQueue> {
      Self.unimplemented("DispatchQueue")
    }

    /// An unimplemented scheduler that can substitute itself for a dispatch queue.
    ///
    /// - Parameter prefix: A string that identifies this scheduler and will prefix all failure
    ///   messages.
    /// - Returns: An unimplemented scheduler.
    public static func unimplemented(_ prefix: String) -> UnimplementedSchedulerOf<DispatchQueue> {
      // NB: `DispatchTime(uptimeNanoseconds: 0) == .now())`. Use `1` for consistency.
      .init(prefix, now: .init(.init(uptimeNanoseconds: 1)))
    }
  }

  extension OperationQueue {
    /// An unimplemented scheduler that can substitute itself for an operation queue.
    public static var unimplemented: UnimplementedSchedulerOf<OperationQueue> {
      Self.unimplemented("OperationQueue")
    }

    /// An unimplemented scheduler that can substitute itself for an operation queue.
    ///
    /// - Parameter prefix: A string that identifies this scheduler and will prefix all failure
    ///   messages.
    /// - Returns: An unimplemented scheduler.
    public static func unimplemented(_ prefix: String) -> UnimplementedSchedulerOf<OperationQueue> {
      .init(prefix, now: .init(.init(timeIntervalSince1970: 0)))
    }
  }

  extension RunLoop {
    /// An unimplemented scheduler that can substitute itself for a run loop.
    public static var unimplemented: UnimplementedSchedulerOf<RunLoop> {
      Self.unimplemented("RunLoop")
    }

    /// An unimplemented scheduler that can substitute itself for a run loop.
    ///
    /// - Parameter prefix: A string that identifies this scheduler and will prefix all failure
    ///   messages.
    /// - Returns: An unimplemented scheduler.
    public static func unimplemented(_ prefix: String) -> UnimplementedSchedulerOf<RunLoop> {
      .init(prefix, now: .init(.init(timeIntervalSince1970: 0)))
    }
  }

  extension AnyScheduler<DispatchQueue> {
    /// An unimplemented scheduler that can substitute itself for a dispatch queue.
    public static var unimplemented: Self {
      .init(DispatchQueue.unimplemented)
    }

    /// An unimplemented scheduler that can substitute itself for a dispatch queue.
    ///
    /// - Parameter prefix: A string that identifies this scheduler and will prefix all failure
    ///   messages.
    /// - Returns: An unimplemented scheduler.
    public static func unimplemented(_ prefix: String) -> Self {
      .init(DispatchQueue.unimplemented(prefix))
    }
  }

  extension AnyScheduler<OperationQueue> {
    /// An unimplemented scheduler that can substitute itself for an operation queue.
    public static var unimplemented: Self {
      .init(OperationQueue.unimplemented)
    }

    /// An unimplemented scheduler that can substitute itself for an operation queue.
    ///
    /// - Parameter prefix: A string that identifies this scheduler and will prefix all failure
    ///   messages.
    /// - Returns: An unimplemented scheduler.
    public static func unimplemented(_ prefix: String) -> Self {
      .init(OperationQueue.unimplemented(prefix))
    }
  }

  extension AnyScheduler<RunLoop> {
    /// An unimplemented scheduler that can substitute itself for a run loop.
    public static var unimplemented: Self {
      .init(RunLoop.unimplemented)
    }

    /// An unimplemented scheduler that can substitute itself for a run loop.
    ///
    /// - Parameter prefix: A string that identifies this scheduler and will prefix all failure
    ///   messages.
    /// - Returns: An unimplemented scheduler.
    public static func unimplemented(_ prefix: String) -> Self {
      .init(RunLoop.unimplemented(prefix))
    }
  }

  @available(iOS, deprecated: 9999.0, message: "Use UnimplementedScheduler type directly instead.")
  @available(macOS, deprecated: 9999.0, message: "Use UnimplementedScheduler type directly instead.")
  @available(tvOS, deprecated: 9999.0, message: "Use UnimplementedScheduler type directly instead.")
  @available(watchOS, deprecated: 9999.0, message: "Use UnimplementedScheduler type directly instead.")
  /// A convenience type to specify an `UnimplementedScheduler` by the scheduler it wraps rather than
  /// by the time type and options type.
  public typealias UnimplementedSchedulerOf<S> = UnimplementedScheduler<S> where S: Combine.Scheduler
#endif
