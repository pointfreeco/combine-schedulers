#if canImport(Combine)
import Combine
public typealias CombineScheduler = Combine.Scheduler

#elseif canImport(OpenCombine)
import OpenCombine
public typealias CombineScheduler = OpenCombine.Scheduler

#endif