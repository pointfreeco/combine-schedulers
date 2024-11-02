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
//typedef struct os_unfair_lock_s {
//  uint32_t _os_unfair_lock_opaque;
//} os_unfair_lock, *os_unfair_lock_t;

public typealias os_unfair_lock_t = Int

func os_unfair_lock() -> os_unfair_lock_t {
  return 1
}

func os_unfair_lock_unlock(_ lock: os_unfair_lock_t) {
  
}

struct Lock {
  internal init() {
   
  }

  internal func cleanupLock() {
    
  }

  internal func lock() {
    
  }

  internal func tryLock() -> Bool {
    return false
  }

  internal func unlock() {
    
  }
}
#endif
