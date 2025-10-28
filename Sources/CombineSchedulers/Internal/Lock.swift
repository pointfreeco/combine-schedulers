#if canImport(Darwin)
  //===----------------------------------------------------------------------===//
  //
  // This source file is part of the Swift.org open source project
  //
  // Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
  // Licensed under Apache License v2.0 with Runtime Library Exception
  //
  // See https://swift.org/LICENSE.txt for license information
  // See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
  //
  //===----------------------------------------------------------------------===//

  import Darwin

  @available(macOS 10.12, iOS 10, tvOS 10, watchOS 3, *)
  typealias Lock = os_unfair_lock_t

  @available(macOS 10.12, iOS 10, tvOS 10, watchOS 3, *)
  extension UnsafeMutablePointer where Pointee == os_unfair_lock_s {
    internal init() {
      let l = UnsafeMutablePointer.allocate(capacity: 1)
      l.initialize(to: os_unfair_lock())
      self = l
    }

    internal func cleanupLock() {
      deinitialize(count: 1)
      deallocate()
    }

    internal func lock() {
      os_unfair_lock_lock(self)
    }

    internal func tryLock() -> Bool {
      let result = os_unfair_lock_trylock(self)
      return result
    }

    internal func unlock() {
      os_unfair_lock_unlock(self)
    }
  }
#else
  import Foundation

  class os_unfair_lock_s: @unchecked Sendable {
    private var mutex: pthread_mutex_t

    init() {
      var attr = pthread_mutexattr_t()
      var mutex = pthread_mutex_t()
      pthread_mutexattr_init(&attr)
      pthread_mutexattr_settype(&attr, Int32(PTHREAD_MUTEX_ERRORCHECK))
      pthread_mutex_init(&mutex, &attr)
      pthread_mutexattr_destroy(&attr)
      self.mutex = mutex
    }

    init(_ mutex: pthread_mutex_t) {
      self.mutex = mutex
    }

    func lock() {
      pthread_mutex_lock(&mutex)
    }

    func unlock() {
      pthread_mutex_unlock(&mutex)
    }

    func cleanupLock() {
      unlock()
    }

    deinit {
      pthread_mutex_destroy(&mutex)
    }
  }

  typealias Lock = os_unfair_lock_s
#endif
