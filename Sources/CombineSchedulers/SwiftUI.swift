#if canImport(Combine) && canImport(SwiftUI)
  import Combine
  import SwiftUI

  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  extension Scheduler {
    /// Specifies an animation to perform when an action is scheduled.
    ///
    /// - Parameter animation: An animation to be performed.
    /// - Returns: A scheduler that performs an animation when a scheduled action is run.
    public func animation(_ animation: Animation? = .default) -> AnySchedulerOf<Self> {
      AnyScheduler(
        minimumTolerance: { self.minimumTolerance },
        now: { self.now },
        scheduleImmediately: { options, action in
          self.schedule(options: options) {
            withAnimation(animation, action)
          }
        },
        delayed: { date, tolerance, options, action in
          self.schedule(after: date, tolerance: tolerance, options: options) {
            withAnimation(animation, action)
          }
        },
        interval: { date, interval, tolerance, options, action in
          self.schedule(after: date, interval: interval, tolerance: tolerance, options: options) {
            withAnimation(animation, action)
          }
        }
      )
    }

    /// Wraps scheduled actions in a transaction.
    ///
    /// - Parameter transaction: A transaction.
    /// - Returns: A scheduler that wraps scheduled actions in a transaction.
    public func transaction(_ transaction: Transaction) -> AnySchedulerOf<Self> {
      AnyScheduler(
        minimumTolerance: { self.minimumTolerance },
        now: { self.now },
        scheduleImmediately: { options, action in
          self.schedule(options: options) {
            withTransaction(transaction, action)
          }
        },
        delayed: { date, tolerance, options, action in
          self.schedule(after: date, tolerance: tolerance, options: options) {
            withTransaction(transaction, action)
          }
        },
        interval: { date, interval, tolerance, options, action in
          self.schedule(after: date, interval: interval, tolerance: tolerance, options: options) {
            withTransaction(transaction, action)
          }
        }
      )
    }
  }
#endif
