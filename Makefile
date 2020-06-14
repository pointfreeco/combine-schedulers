format:
	swift format --in-place --recursive ./Package.swift ./Sources ./Tests

test-swift:
	swift test \
		--enable-pubgrub-resolver \
		--enable-test-discovery \
		--parallel

.PHONY: format test-swift
