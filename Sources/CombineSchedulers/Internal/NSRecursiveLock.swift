import Foundation

extension NSRecursiveLock {
  @inlinable @discardableResult
  func sync<R>(operation: () -> R) -> R {
    self.lock()
    defer { self.unlock() }
    return operation()
  }
}
