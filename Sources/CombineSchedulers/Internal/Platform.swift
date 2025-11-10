#if canImport(Combine)
  import Combine

  public typealias _CombineScheduler = Combine.Scheduler
#elseif canImport(OpenCombine)
  import OpenCombine

  public typealias _CombineScheduler = OpenCombine.Scheduler
#endif
