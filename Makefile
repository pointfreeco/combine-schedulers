PLATFORM_IOS = iOS Simulator,name=iPhone 11 Pro Max
PLATFORM_MACOS = macOS
PLATFORM_TVOS = tvOS Simulator,name=Apple TV 4K (at 1080p)
PLATFORM_WATCHOS = watchOS Simulator,name=Apple Watch Series 4 - 44mm

test:
	swift test --enable-test-discovery
	xcodebuild test \
		-scheme combine-schedulers \
		-destination platform="$(PLATFORM_IOS)"
	xcodebuild test \
		-scheme combine-schedulers \
		-destination platform="$(PLATFORM_MACOS)"
	xcodebuild test \
		-scheme combine-schedulers \
		-destination platform="$(PLATFORM_TVOS)"
	xcodebuild build \
		-scheme CombineSchedulers_watchOS \
		-destination platform="$(PLATFORM_WATCHOS)"

format:
	swift format --in-place --recursive ./Package.swift ./Sources ./Tests

.PHONY: format test-swift
