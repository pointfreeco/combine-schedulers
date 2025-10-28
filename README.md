# ⏰ Combine Schedulers

[![CI](https://github.com/pointfreeco/combine-schedulers/workflows/CI/badge.svg)](https://github.com/pointfreeco/combine-schedulers/actions?query=workflow%3ACI)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fcombine-schedulers%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pointfreeco/combine-schedulers)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fcombine-schedulers%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pointfreeco/combine-schedulers)

A few schedulers that make working with Combine more testable and more versatile.

* [Motivation](#motivation)
* [Learn more](#learn-more)
  * [`AnyScheduler`](#anyscheduler)
  * [`TestScheduler`](#testscheduler)
  * [`ImmediateScheduler`](#immediatescheduler)
  * [Animated schedulers](#animated-schedulers)
  * [`UnimplementedScheduler`](#unimplementedscheduler)
  * [`UIScheduler`](#uischeduler)
  * [Concurrency APIs](#concurrency-apis)
  * [`Publishers.Timer`](#publisherstimer)
* [Installation](#installation)
* [Documentation](#documentation)
* [Other libraries](#other-libraries)

## Motivation

The Combine framework provides the `Scheduler` protocol, which is a powerful abstraction for describing how and when units of work are executed. It unifies many disparate ways of executing work, such as `DispatchQueue`, `RunLoop` and `OperationQueue`.

However, the moment you use any of these schedulers in your reactive code you instantly make the publisher asynchronous and therefore much harder to test, forcing you to use expectations and waits for time to pass as your publisher executes.

This library provides new schedulers that allow you to turn any asynchronous publisher into a synchronous one for ease of testing and debugging.

## Learn More

This library was designed over the course of many episodes on [Point-Free](https://www.pointfree.co), a video series exploring functional programming and Swift hosted by [Brandon Williams](https://github.com/mbrandonw) and [Stephen Celis](https://github.com/stephencelis).

You can watch all of the episodes [here](https://www.pointfree.co/collections/combine/schedulers).

<a href="https://www.pointfree.co/collections/combine/schedulers">
  <img alt="video poster image" src="https://d3rccdn33rt8ze.cloudfront.net/episodes/0106.jpeg" width="480">
</a>

### `AnyScheduler`

The `AnyScheduler` provides a type-erasing wrapper for the `Scheduler` protocol, which can be useful for being generic over many types of schedulers without needing to actually introduce a generic to your code. The Combine framework ships with many type-erasing wrappers, such as `AnySubscriber`, `AnyPublisher` and `AnyCancellable`, yet for some reason does not ship with `AnyScheduler`.

This type is useful for times that you want to be able to customize the scheduler used in some code from the outside, but you don't want to introduce a generic to make it customizable. For example, suppose you have an `ObservableObject` view model that performs an API request when a method is called:

```swift
class EpisodeViewModel: ObservableObject {
  @Published var episode: Episode?

  let apiClient: ApiClient

  init(apiClient: ApiClient) {
    self.apiClient = apiClient
  }

  func reloadButtonTapped() {
    self.apiClient.fetchEpisode()
      .receive(on: DispatchQueue.main)
      .assign(to: &self.$episode)
  }
}
```

Notice that we are using `DispatchQueue.main` in the `reloadButtonTapped` method because the `fetchEpisode` endpoint most likely delivers its output on a background thread (as is the case with `URLSession`).

This code seems innocent enough, but the presence of `.receive(on: DispatchQueue.main)` makes this code harder to test since you have to use `XCTest` expectations to explicitly wait a small amount of time for the queue to execute. This can lead to flakiness in tests and make test suites take longer to execute than necessary.

One way to fix this testing problem is to use an ["immediate" scheduler](#immediatescheduler) instead of `DispatchQueue.main`, which will cause `fetchEpisode` to deliver its output as soon as possible with no thread hops. In order to allow for this we would need to inject a scheduler into our view model so that we can control it from the outside:

```swift
class EpisodeViewModel<S: Scheduler>: ObservableObject {
  @Published var episode: Episode?

  let apiClient: ApiClient
  let scheduler: S

  init(apiClient: ApiClient, scheduler: S) {
    self.apiClient = apiClient
    self.scheduler = scheduler
  }

  func reloadButtonTapped() {
    self.apiClient.fetchEpisode()
      .receive(on: self.scheduler)
      .assign(to: &self.$episode)
  }
}
```

Now we can initialize this view model in production by using `DispatchQueue.main` and we can initialize it in tests using `DispatchQueue.immediate`. Sounds like a win!

However, introducing this generic to our view model is quite heavyweight as it is loudly announcing to the outside world that this type uses a scheduler, and worse it will end up infecting any code that touches this view model that also wants to be testable. For example, any view that uses this view model will need to introduce a generic if it wants to also be able to control the scheduler, which would be useful if we wanted to write [snapshot tests](https://github.com/pointfreeco/swift-snapshot-testing).

Instead of introducing a generic to allow for substituting in different schedulers we can use `AnyScheduler`. It allows us to be somewhat generic in the scheduler, but without actually introducing a generic.

Instead of holding a generic scheduler in our view model we can say that we only want a scheduler whose associated types match that of `DispatchQueue`:

```swift
class EpisodeViewModel: ObservableObject {
  @Published var episode: Episode?

  let apiClient: ApiClient
  let scheduler: AnySchedulerOf<DispatchQueue>

  init(apiClient: ApiClient, scheduler: AnySchedulerOf<DispatchQueue>) {
    self.apiClient = apiClient
    self.scheduler = scheduler
  }

  func reloadButtonTapped() {
    self.apiClient.fetchEpisode()
      .receive(on: self.scheduler)
      .assign(to: &self.$episode)
  }
}
```

Then, in production we can create a view model that uses a live `DispatchQueue`, but we just have to first erase its type:

```swift
let viewModel = EpisodeViewModel(
  apiClient: ...,
  scheduler: DispatchQueue.main.eraseToAnyScheduler()
)
```

For common schedulers, like `DispatchQueue`, `OperationQueue`, and `RunLoop`, there is even a static helper on `AnyScheduler` that further simplifys this:

```swift
let viewModel = EpisodeViewModel(
  apiClient: ...,
  scheduler: .main
)
```

Then in tests we can use an immediate scheduler:

```swift
let viewModel = EpisodeViewModel(
  apiClient: ...,
  scheduler: .immediate
)
```

So, in general, `AnyScheduler` is great for allowing one to control what scheduler is used in classes, functions, etc. without needing to introduce a generic, which can help simplify the code and reduce implementation details from leaking out.

### `TestScheduler`

A scheduler whose current time and execution can be controlled in a deterministic manner. This scheduler is useful for testing how the flow of time effects publishers that use asynchronous operators, such as `debounce`, `throttle`, `delay`, `timeout`, `receive(on:)`, `subscribe(on:)` and more.

For example, consider the following `race` operator that runs two futures in parallel, but only emits the first one that completes:

```swift
func race<Output, Failure: Error>(
  _ first: Future<Output, Failure>,
  _ second: Future<Output, Failure>
) -> AnyPublisher<Output, Failure> {
  first
    .merge(with: second)
    .prefix(1)
    .eraseToAnyPublisher()
}
```

Although this publisher is quite simple we may still want to write some tests for it.

To do this we can create a test scheduler and create two futures, one that emits after a second and one that emits after two seconds:

```swift
let scheduler = DispatchQueue.test

let first = Future<Int, Never> { callback in
  scheduler.schedule(after: scheduler.now.advanced(by: 1)) { callback(.success(1)) }
}
let second = Future<Int, Never> { callback in
  scheduler.schedule(after: scheduler.now.advanced(by: 2)) { callback(.success(2)) }
}
```

And then we can race these futures and collect their emissions into an array:

```swift
var output: [Int] = []
let cancellable = race(first, second).sink { output.append($0) }
```

And then we can deterministically move time forward in the scheduler to see how the publisher emits. We can start by moving time forward by one second:

```swift
scheduler.advance(by: 1)
XCTAssertEqual(output, [1])
```

This proves that we get the first emission from the publisher since one second of time has passed. If we further advance by one more second we can prove that we do not get anymore emissions:

```swift
scheduler.advance(by: 1)
XCTAssertEqual(output, [1])
```

This is a very simple example of how to control the flow of time with the test scheduler, but this technique can be used to test any publisher that involves Combine's asynchronous operations.

### `ImmediateScheduler`

The Combine framework comes with an `ImmediateScheduler` type of its own, but it defines all new types for the associated types of `SchedulerTimeType` and `SchedulerOptions`. This means you cannot easily swap between a live `DispatchQueue` and an "immediate" `DispatchQueue` that executes work synchronously. The only way to do that would be to introduce generics to any code making use of that scheduler, which can become unwieldy.

So, instead, this library's `ImmediateScheduler` uses the same associated types as an existing scheduler, which means you can use `DispatchQueue.immediate` to have a scheduler that looks like a dispatch queue but executes its work immediately. Similarly you can construct `RunLoop.immediate` and `OperationQueue.immediate`.

This scheduler is useful for writing tests against publishers that use asynchrony operators, such as `receive(on:)`, `subscribe(on:)` and others, because it forces the publisher to emit immediately rather than needing to wait for thread hops or delays using `XCTestExpectation`.

This scheduler is different from `TestScheduler` in that you cannot explicitly control how time flows through your publisher, but rather you are instantly collapsing time into a single point.

As a basic example, suppose you have a view model that loads some data after waiting for 10 seconds from when a button is tapped:

```swift
class HomeViewModel: ObservableObject {
  @Published var episodes: [Episode]?

  let apiClient: ApiClient

  init(apiClient: ApiClient) {
    self.apiClient = apiClient
  }

  func reloadButtonTapped() {
    Just(())
      .delay(for: .seconds(10), scheduler: DispatchQueue.main)
      .flatMap { apiClient.fetchEpisodes() }
      .assign(to: &self.$episodes)
  }
}
```

In order to test this code you would literally need to wait 10 seconds for the publisher to emit:

```swift
func testViewModel() {
  let viewModel = HomeViewModel(apiClient: .mock)

  viewModel.reloadButtonTapped()

  _ = XCTWaiter.wait(for: [XCTestExpectation()], timeout: 10)

  XCTAssert(viewModel.episodes, [Episode(id: 42)])
}
```

Alternatively, we can explicitly pass a scheduler into the view model initializer so that it can be controller from the outside:

```swift
class HomeViewModel: ObservableObject {
  @Published var episodes: [Episode]?

  let apiClient: ApiClient
  let scheduler: AnySchedulerOf<DispatchQueue>

  init(apiClient: ApiClient, scheduler: AnySchedulerOf<DispatchQueue>) {
    self.apiClient = apiClient
    self.scheduler = scheduler
  }

  func reloadButtonTapped() {
    Just(())
      .delay(for: .seconds(10), scheduler: self.scheduler)
      .flatMap { self.apiClient.fetchEpisodes() }
      .assign(to: &self.$episodes)
  }
}
```

And then in tests use an immediate scheduler:

```swift
func testViewModel() {
  let viewModel = HomeViewModel(
    apiClient: .mock,
    scheduler: .immediate
  )

  viewModel.reloadButtonTapped()

  // No more waiting...

  XCTAssert(viewModel.episodes, [Episode(id: 42)])
}
```

### Animated schedulers

CombineSchedulers comes with helpers that aid in asynchronous animations in both SwiftUI and UIKit.

If a SwiftUI state mutation should be animated, you can invoke the `animation` and `transaction` methods to transform an existing scheduler into one that schedules its actions with an animation or in a transaction. These APIs mirror SwiftUI's `withAnimation` and `withTransaction` functions, which are invoked by the animated scheduler.

For example, to animate an API response in your view model, you can specify that the scheduler that receives this state should be animated:

```swift
self.apiClient.fetchEpisode()
  .receive(on: self.scheduler.animation())
  .assign(to: &self.$episode)
```

If you are powering a UIKit feature with Combine, you can use the `.animate` method, which mirrors `UIView.animate`:

```swift
self.apiClient.fetchEpisode()
  .receive(on: self.scheduler.animate(withDuration: 0.3))
  .assign(to: &self.$episode)
```

### `UnimplementedScheduler`

A scheduler that causes a test to fail if it is used.

This scheduler can provide an additional layer of certainty that a tested code path does not require the use of a scheduler.

As a view model becomes more complex, only some of its logic may require a scheduler. When writing unit tests for any logic that does _not_ require a scheduler, one should provide an unimplemented scheduler, instead. This documents, directly in the test, that the feature does not use a scheduler. If it did, or ever does in the future, the test will fail.

For example, the following view model has a couple responsibilities:

```swift
class EpisodeViewModel: ObservableObject {
  @Published var episode: Episode?

  let apiClient: ApiClient
  let mainQueue: AnySchedulerOf<DispatchQueue>

  init(apiClient: ApiClient, mainQueue: AnySchedulerOf<DispatchQueue>) {
    self.apiClient = apiClient
    self.mainQueue = mainQueue
  }

  func reloadButtonTapped() {
    self.apiClient.fetchEpisode()
      .receive(on: self.mainQueue)
      .assign(to: &self.$episode)
  }

  func favoriteButtonTapped() {
    self.episode?.isFavorite.toggle()
  }
}
```

  * It lets the user tap a button to refresh some episode data
  * It lets the user toggle if the episode is one of their favorites

The API client delivers the episode on a background queue, so the view model must receive it on its main queue before mutating its state.

Tapping the favorite button, however, involves no scheduling. This means that a test can be written with an unimplemented scheduler:

```swift
func testFavoriteButton() {
  let viewModel = EpisodeViewModel(
    apiClient: .mock,
    mainQueue: .unimplemented
  )
  viewModel.episode = .mock

  viewModel.favoriteButtonTapped()
  XCTAssert(viewModel.episode?.isFavorite == true)

  viewModel.favoriteButtonTapped()
  XCTAssert(viewModel.episode?.isFavorite == false)
}
```

With `.unimplemented`, this test strongly declares that favoriting an episode does not need a scheduler to do the job, which means it is reasonable to assume that the feature is simple and does not involve any asynchrony.

In the future, should favoriting an episode fire off an API request that involves a scheduler, this test will begin to fail, which is a good thing! This will force us to address the complexity that was introduced. Had we used any other scheduler, it would quietly receive this additional work and the test would continue to pass.

### `UIScheduler`

A scheduler that executes its work on the main queue as soon as possible. This scheduler is inspired by the [equivalent](https://github.com/ReactiveCocoa/ReactiveSwift/blob/58d92aa01081301549c48a4049e215210f650d07/Sources/Scheduler.swift#L92) scheduler in the [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift) project.

If `UIScheduler.shared.schedule` is invoked from the main thread then the unit of work will be performed immediately. This is in contrast to `DispatchQueue.main.schedule`, which will incur a thread hop before executing since it uses `DispatchQueue.main.async` under the hood.

This scheduler can be useful for situations where you need work executed as quickly as possible on the main thread, and for which a thread hop would be problematic, such as when performing animations.

### Concurrency APIs

This library provides `async`-friendly APIs for interacting with Combine schedulers.

```swift
// Suspend the current task for 1 second
try await scheduler.sleep(for: .seconds(1))

// Perform work every 1 second
for await instant in scheduler.timer(interval: .seconds(1)) {
  ...
}
``` 

### `Publishers.Timer`

A publisher that emits a scheduler's current time on a repeating interval.

This publisher is an alternative to Foundation's `Timer.publisher`, with its primary difference being that it allows you to use any scheduler for the timer, not just `RunLoop`. This is useful because the `RunLoop` scheduler is not testable in the sense that if you want to write tests against a publisher that makes use of `Timer.publisher` you must explicitly wait for time to pass in order to get emissions. This is likely to lead to fragile tests and greatly bloat the time your tests take to execute.

It can be used much like Foundation's timer, except you specify a scheduler rather than a run loop:

```swift
Publishers.Timer(every: .seconds(1), scheduler: DispatchQueue.main)
  .autoconnect()
  .sink { print("Timer", $0) }
```

Alternatively you can call the `timerPublisher` method on a scheduler in order to derive a repeating timer on that scheduler:

```swift
DispatchQueue.main.timerPublisher(every: .seconds(1))
  .autoconnect()
  .sink { print("Timer", $0) }
```

But the best part of this timer is that you can use it with `TestScheduler` so that any Combine code you write involving timers becomes more testable. This shows how we can easily simulate the idea of moving time forward 1,000 seconds in a timer:

```swift
let scheduler = DispatchQueue.test
var output: [Int] = []

Publishers.Timer(every: 1, scheduler: scheduler)
  .autoconnect()
  .sink { _ in output.append(output.count) }
  .store(in: &self.cancellables)

XCTAssertEqual(output, [])

scheduler.advance(by: 1)
XCTAssertEqual(output, [0])

scheduler.advance(by: 1)
XCTAssertEqual(output, [0, 1])

scheduler.advance(by: 1_000)
XCTAssertEqual(output, Array(0...1_001))
```

## Compatibility

This library is compatible with iOS 13.2 and higher. Please note that there are bugs in the Combine framework and iOS 13.1 and lower that will cause crashes when trying to compare `DispatchQueue.SchedulerTimeType` values, which is an operation that the `TestScheduler` depends on.

## Installation

You can add CombineSchedulers to an Xcode project by adding it as a package dependency.

  1. From the **File** menu, select **Swift Packages › Add Package Dependency…**
  2. Enter "https://github.com/pointfreeco/combine-schedulers" into the package repository URL text field
  3. Depending on how your project is structured:
      - If you have a single application target that needs access to the library, then add **CombineSchedulers** directly to your application.
      - If you want to use this library from multiple targets you must create a shared framework that depends on **CombineSchedulers**, and then depend on that framework from your other targets.

### Linux usage
To use combine-schedulers in as a package dependency on Linux, add the `OpenCombineSchedulers` trait.
```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/pointfreeco/combine-schedulers", from: "1.0.3", traits: ["OpenCombineSchedulers"]),
    ],
    ...
```
To build the `combine-schedulers` package locally on Linux, add the `OpenCombineSchedulers` tags in the command line:
```shell
cd combine-schedulers
swift build --traits OpenCombineSchedulers
swift test --traits OpenCombineSchedulers
```

## Documentation

The latest documentation for Combine Schedulers' APIs is available [here](https://pointfreeco.github.io/combine-schedulers/).

## Other Libraries

* [Entwine](https://github.com/tcldr/Entwine)

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
