PLATFORM_IOS = iOS Simulator,name=iPhone 11 Pro Max
PLATFORM_MACOS = macOS
PLATFORM_TVOS = tvOS Simulator,name=Apple TV
PLATFORM_WATCHOS = watchOS Simulator,name=Apple Watch Series 5 - 44mm

test:
	swift test
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
		-scheme combine-schedulers \
		-destination platform="$(PLATFORM_WATCHOS)"

build-for-library-evolution:
	swift build \
		-c release \
		--target CombineSchedulers \
		-Xswiftc -emit-module-interface \
		-Xswiftc -enable-library-evolution

format:
	swift format --in-place --recursive ./Package.swift ./Sources ./Tests

.PHONY: format test-swift
