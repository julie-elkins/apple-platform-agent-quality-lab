# Project memory

Last updated: 2026-10-27

## Purpose

Apple Platform Agent Quality Lab is a portfolio and interview demonstration
for evaluating an agentic workflow on Apple platforms. It shows the full
evidence path:

```text
request → model response → tool call → tool result → evaluation → release gate
```

The project is intentionally local-first. It uses deterministic synthetic
scenarios and does not require credentials, network access, Reminders, Calendar,
or personal data.

## Current implementation

- Swift Package Manager executable and native AppKit macOS app.
- Four deterministic evaluation scenarios.
- Component, trajectory, and end-to-end scoring.
- Custom deterministic release gate remains authoritative.
- Optional live Foundation Models mode.
- `FollowUpTaskEntity` and `EntityStringQuery`: a typed synthetic task that
  Siri/Shortcuts can resolve.
- `CreateFollowUpIntent` and `InspectFollowUpTaskIntent`.
- Two App Shortcuts.
- Supplemental Apple Evaluations adapter.
- Scrollable white trace/notes panel in the native app.
- Plain-language explanation boxes for the evidence path, buttons, and current
  `PASS` or `FAIL` meaning.
- Baseline/negative-control run summary and history, including highlighted
  failures and an explicit explanation that baseline reruns are fresh runs,
  not automatic repairs.
- Xcode project and `AppIntentsTesting` system-boundary test target.

## Verified state

- `swift test`: 3 tests passed.
- `swift run apple-agent-quality-lab --live-foundation-model`:
  4/4 scenarios passed, minimum score 1.00, release gate `PASS`.
- `./scripts/build-app.sh`: Xcode build succeeds and extracts
  `Contents/Resources/Metadata.appintents`.
- The packaged app launches successfully with `open`.
- The app's explanation boxes render correctly, and the dynamic result text
  changes for both the normal pass and negative-control failure paths.
- The complete visible sequence works: baseline `PASS` → negative control
  `FAIL` as expected → baseline `PASS` restored.
- The launch fix set the Xcode target's `EXECUTABLE_NAME` to
  `apple-agent-quality-lab`, matching `Info.plist` and the SwiftPM fallback.

## Operating-system boundary

The current Mac is running macOS 26.7.2 and is managed by the employer. This is
the latest permitted update, but it still does not satisfy the macOS 27.0
runtime requirement for the `AppIntentsTesting` and `Evaluations` execution
paths.

The Xcode project uses Xcode 27.1 and the macOS 27 SDK. The native test target
builds successfully, but `xcodebuild test` cannot execute it on macOS 26.7.2
because the test target's deployment target is macOS 27.0. This is an honest
environment limitation, not a source failure.

On the current OS, Apple Evaluations reports `UNAVAILABLE` and the custom
release gate remains authoritative. Do not change that to a passing result
without actual Apple Evaluations runtime evidence.

## Resume instructions

From the project directory:

```text
./scripts/build-app.sh
open "dist/Apple Platform Agent Quality Lab.app"
swift test
swift run apple-agent-quality-lab --live-foundation-model
```

When macOS 27 or a compatible test machine is available, run:

```text
xcodebuild -project AppleAgentQualityLab.xcodeproj -scheme AppleAgentQualityLab -configuration Debug test CODE_SIGNING_ALLOWED=NO
```

Then run the negative control and confirm the release gate fails for the
deliberately incorrect tool path:

```text
swift run apple-agent-quality-lab --negative-control
```

The negative-control command is expected to exit with status 1.

## Important files

- `Sources/AppleAgentQualityLab/Models.swift`: report and score models.
- `Sources/AppleAgentQualityLab/EvaluationGate.swift`: authoritative gate.
- `Sources/AppleAgentQualityLab/AppleIntentsIntegration.swift`: entity, query,
  intents, and shortcuts.
- `Sources/AppleAgentQualityLab/AppleEvaluationsAdapter.swift`: supplemental
  Apple Evaluations integration.
- `Sources/AppleAgentQualityLab/MacOSApp.swift`: native app UI.
- `XcodeIntegration/AppleAgentQualityLabIntentTests.swift`: native
  system-boundary tests.
- `scripts/build-app.sh`: Xcode-first app packaging with SwiftPM fallback.
- `docs/INTERVIEW_WALKTHROUGH.md`: recommended interview demonstration.
- `docs/XCODE_INTEGRATION.md`: Xcode and runtime-boundary notes.
