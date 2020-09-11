import Combine

extension AnyScheduler {
  public static func unimplemented(file: StaticString = #file, line: UInt = #line) -> Self {
    Self(
      minimumTolerance: { fatalError(file: file, line: line) },
      now: { fatalError(file: file, line: line) },
      scheduleImmediately: { _, _ in fatalError(file: file, line: line) },
      delayed: { _, _, _, _ in fatalError(file: file, line: line) },
      interval: { _, _, _, _, _ in fatalError(file: file, line: line) }
    )
  }
}
