#if canImport(SwiftUI)
import Combine
import SwiftUI

extension Scheduler {
  public func animation(_ animation: Animation? = .default) -> AnyScheduler<SchedulerTimeType, SchedulerOptions> {
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
}
#endif
