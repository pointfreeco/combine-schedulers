import Foundation

extension NSRecursiveLock {
  @inlinable @discardableResult
  func sync<R>(operation: () -> R) -> R {
    self.lock()
    defer { self.unlock() }
    return operation()
  }
}

extension NSRecursiveLock {
  @inlinable @discardableResult
  func sync<R>(operation: () async -> R) async -> R {
    self.lock()
    defer { self.unlock() }
    return await operation()
  }
}
