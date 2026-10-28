# Project memory

Last updated: 2026-10-28

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
- Failure analysis and recommended remediation panel that describes the
  observed failure, corrective action, and rerun step without changing code.
- Visible section titles above every guidance, summary, remediation, and trace
  box so a first-time user can read the interface in order.
- Separate Local Data Mode window for a user-selected Markdown, text, or JSON
  file. It is read-only, limits input to 1 MB, shows a source preview, and
  records `local-file.read` with `readOnly=true` in the evidence trace.
- Local Data Mode keeps the source preview, evaluation details, and evidence
  trace in separate scrollable areas so long model responses cannot overlap
  the next section.
- The main Quality Lab now shows the recommended five-step demo flow, and
  Local Data Mode shows its four local steps with a visible `Return to Quality
  Lab` button, so the two-window workflow is explicit.
- Local Data Mode uses the same response, trajectory, and end-to-end gate as
  the synthetic scenarios but never changes the stable baseline result. It
  uses a deterministic grounded fallback and, when available, follows with an
  Apple Foundation Models response.
- Xcode project and `AppIntentsTesting` system-boundary test target.

## Verified state

- `swift test`: 5 tests passed, including Markdown and JSON local-data
  importer/evidence checks.
- `swift run apple-agent-quality-lab --live-foundation-model`:
  4/4 scenarios passed, minimum score 1.00, release gate `PASS`.
- `./scripts/build-app.sh`: Xcode build succeeds and extracts
  `Contents/Resources/Metadata.appintents`.
- The packaged app launches successfully with `open`.
- The app's explanation boxes render correctly, and the dynamic result text
  changes for both the normal pass and negative-control failure paths.
- The complete visible sequence works: baseline `PASS` → negative control
  `FAIL` as expected → baseline `PASS` restored.
- The negative-control panel recommends using `CreateFollowUpIntent` and
  requiring a successful tool result before claiming task completion.
- The packaged app displays the section titles clearly, and the Swift tests
  still pass after the UI update.
- The refreshed packaged app visibly shows the numbered workflow in the main
  window and the local steps plus return button in Local Data Mode.
- The packaged app includes an `Open local data mode` button. The separate
  window was visually verified with its read-only safety explanation, file
  picker, source preview, result, evaluation-details, and evidence-trace
  areas. The evaluation-details area was corrected from a fixed-height label to
  a scrollable text view after a long README response exposed overlap.
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
- `Sources/AppleAgentQualityLab/LocalDataMode.swift`: read-only local importer,
  local-data scenario, and evidence-producing agent.
- `Sources/AppleAgentQualityLab/LocalDataWindow.swift`: separate local-data UI.
- `XcodeIntegration/AppleAgentQualityLabIntentTests.swift`: native
  system-boundary tests.
- `scripts/build-app.sh`: Xcode-first app packaging with SwiftPM fallback.
- `docs/INTERVIEW_WALKTHROUGH.md`: recommended interview demonstration.
- `docs/XCODE_INTEGRATION.md`: Xcode and runtime-boundary notes.
