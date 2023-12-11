Pod::Spec.new do |spec|
  spec.name = "combine-schedulers"
  spec.version = "1.0.0"
  spec.license = "MIT License"
  spec.summary = "A few schedulers that make working with Combine more testable and more versatile."

  spec.description = <<-DESC
The Combine framework provides the Scheduler protocol, which is a powerful abstraction for describing how and when units of work are executed. It unifies many disparate ways of executing work, such as DispatchQueue, RunLoop and OperationQueue.

However, the moment you use any of these schedulers in your reactive code you instantly make the publisher asynchronous and therefore much harder to test, forcing you to use expectations and waits for time to pass as your publisher executes.

This library provides new schedulers that allow you to turn any asynchronous publisher into a synchronous one for ease of testing and debugging.
                   DESC
  spec.source = { :git => "https://github.com/rafe-g/combine-schedulers.git", :tag => "v#{spec.version}" }
  spec.homepage = "https://github.com/rafe-g/combine-schedulers"
  spec.authors = { "Rafael Gutierrez" => "rafaelg@duck.com" }
  spec.swift_version = "5.8"
  spec.ios.deployment_target = '13.0'
  spec.source_files = "Sources/**/*.{swift}"
end
