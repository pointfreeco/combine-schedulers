#if canImport(Combine)
  import Combine

  public typealias SchedulerProtocol = Combine.Scheduler
#elseif canImport(OpenCombine)
  import OpenCombine

  public typealias SchedulerProtocol = OpenCombine.Scheduler
#endif
