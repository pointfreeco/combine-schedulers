#if canImport(UIKit) && !os(watchOS) && canImport(OpenCombineShim)
  import OpenCombineShim
  import UIKit

  extension Scheduler {
    /// Wraps scheduled actions in `UIView.animate`.
    ///
    /// - Parameter duration: The `duration` parameter passed to `UIView.animate`.
    /// - Parameter delay: The `delay` parameter passed to `UIView.animate`.
    /// - Parameter animationOptions: The `options` parameter passed to `UIView.animate`
    /// - Returns: A scheduler that wraps scheduled actions in `UIView.animate`.
    @MainActor
    public func animate(
      withDuration duration: TimeInterval,
      delay: TimeInterval = 0,
      options animationOptions: UIView.AnimationOptions = []
    ) -> AnySchedulerOf<Self> {
      AnyScheduler(
        minimumTolerance: { self.minimumTolerance },
        now: { self.now },
        scheduleImmediately: { options, action in
          self.schedule(options: options) {
            UIView.animate(
              withDuration: duration,
              delay: delay,
              options: animationOptions,
              animations: action
            )
          }
        },
        delayed: { date, tolerance, options, action in
          self.schedule(after: date, tolerance: tolerance, options: options) {
            UIView.animate(
              withDuration: duration,
              delay: delay,
              options: animationOptions,
              animations: action
            )
          }
        },
        interval: { date, interval, tolerance, options, action in
          self.schedule(after: date, interval: interval, tolerance: tolerance, options: options) {
            UIView.animate(
              withDuration: duration,
              delay: delay,
              options: animationOptions,
              animations: action
            )
          }
        }
      )
    }

    /// Wraps scheduled actions in `UIView.animate`.
    ///
    /// - Parameter duration: The `duration` parameter passed to `UIView.animate`.
    /// - Parameter delay: The `delay` parameter passed to `UIView.animate`.
    /// - Parameter dampingRatio: The `dampingRatio` parameter passed to `UIView.animate`
    /// - Parameter velocity: The `velocity` parameter passed to `UIView.animate`
    /// - Parameter animationOptions: The `options` parameter passed to `UIView.animate`
    /// - Returns: A scheduler that wraps scheduled actions in `UIView.animate`.
    @MainActor
    public func animate(
      withDuration duration: TimeInterval,
      delay: TimeInterval = 0,
      usingSpringWithDamping dampingRatio: CGFloat,
      initialSpringVelocity velocity: CGFloat,
      options animationOptions: UIView.AnimationOptions
    ) -> AnySchedulerOf<Self> {
      AnyScheduler(
        minimumTolerance: { self.minimumTolerance },
        now: { self.now },
        scheduleImmediately: { options, action in
          self.schedule(options: options) {
            UIView.animate(
              withDuration: duration,
              delay: delay,
              usingSpringWithDamping: dampingRatio,
              initialSpringVelocity: velocity,
              options: animationOptions,
              animations: action
            )
          }
        },
        delayed: { date, tolerance, options, action in
          self.schedule(after: date, tolerance: tolerance, options: options) {
            UIView.animate(
              withDuration: duration,
              delay: delay,
              usingSpringWithDamping: dampingRatio,
              initialSpringVelocity: velocity,
              options: animationOptions,
              animations: action
            )
          }
        },
        interval: { date, interval, tolerance, options, action in
          self.schedule(after: date, interval: interval, tolerance: tolerance, options: options) {
            UIView.animate(
              withDuration: duration,
              delay: delay,
              usingSpringWithDamping: dampingRatio,
              initialSpringVelocity: velocity,
              options: animationOptions,
              animations: action
            )
          }
        }
      )
    }
  }
#endif
