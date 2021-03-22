format:
	swift format --in-place --recursive ./Package.swift ./Sources ./Tests

test-swift:
	swift test \
		--enable-test-discovery

.PHONY: format test-swift
