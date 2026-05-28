#if canImport(Combine)
  public import Combine

  public typealias _CombineScheduler = Combine.Scheduler
#elseif canImport(OpenCombine)
  public import OpenCombine

  public typealias _CombineScheduler = OpenCombine.Scheduler
#endif
