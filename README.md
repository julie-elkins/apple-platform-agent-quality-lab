# Apple Platform Agent Quality Lab

A local-first evaluation lab for an Apple-style intelligent app.

The project demonstrates the complete decision path:

```text
request → model response → tool call → tool result → evaluation → release gate
```

The current vertical slice is deliberately provider-neutral and runs with Swift
Command Line Tools. It uses deterministic synthetic scenarios so a reviewer can
inspect the evaluation contract without credentials, network access, or personal
Apple data.

## What it evaluates

- Response evidence for summarization.
- Grounded recommendations backed by retrieved notes.
- App-Intent-shaped action calls.
- App Entity resolution and App Shortcut metadata.
- Error recovery that reports failure instead of inventing success.
- Component, trajectory, and end-to-end scores.
- Supplemental Apple Evaluations metrics when macOS 27 is available.
- A release decision with `PASS`, `FAIL`, `RERUN REQUIRED`, or `UNAVAILABLE`.

## Run it

```bash
swift run apple-agent-quality-lab
```

The command writes `apple-agent-quality-report.json` in the current directory.
The report contains the trace, evaluation results, framework availability, and
release decision. The executable also checks that every scenario produced
evidence, that the honest error-recovery case remains covered, and that the
deterministic release gate passes.

Open the reviewer-facing native macOS app with:

```bash
./scripts/build-app.sh
open "dist/Apple Platform Agent Quality Lab.app"
```

The app shows the release decision, each scenario's component, trajectory, and
end-to-end scores, plus the full trace. The CLI and the app use the same
evaluation logic.
Use the negative-control button to run an intentionally wrong tool path and
observe the gate fail with its trace.

The same failure path can be checked without opening the app:

```bash
swift run apple-agent-quality-lab --negative-control
```

That command is expected to exit with status `1`, because the gate correctly
rejects the deliberately broken scenario.

The app also includes a separate Local Data Mode window. Use it to select a
de-identified Markdown, text, or JSON file and inspect a grounded local
evaluation. The importer is read-only, limits input to 1 MB, does not upload
the file, and does not write back to it. A local-data run is deliberately
separate from the synthetic release gate so real input cannot change the
stable baseline evidence.

## Apple-native integration boundary

The source detects whether `FoundationModels`, `AppIntents`,
`AppIntentsTesting`, and `Evaluations` are available to the current build.
The app exposes a synthetic `FollowUpTaskEntity`, an `EntityStringQuery`, and
two App Shortcuts without reading personal Reminders or Calendar data.

The executable includes an optional live mode for the on-device Apple Foundation
Model:

```bash
swift run apple-agent-quality-lab --live-foundation-model
```

The live mode replaces the summarization response with an actual Foundation
Models response when the model is available. The deterministic scenarios remain
the release gate because a live model is variable and must not silently decide
whether the evaluator itself is healthy.

A full Xcode installation is required for the `AppIntentsTesting` integration
that exercises the system boundary in CI. The project builds that test target
successfully with Xcode 27.1:

```bash
xcodebuild -project AppleAgentQualityLab.xcodeproj \
  -scheme AppleAgentQualityLab \
  -configuration Debug \
  build-for-testing \
  CODE_SIGNING_ALLOWED=NO
```

The installed `AppIntentsTesting` and `Evaluations` APIs require macOS 27.0 at
runtime. This machine is currently on macOS 26.7.2, so the local package tests
run the entity, shortcut, and availability checks, while the Xcode system-
boundary target compiles but `xcodebuild test` correctly refuses to run it.
Run the same scheme on macOS 27 or newer to execute the native test.

That boundary is intentional: the project reports `UNAVAILABLE` for missing
evidence rather than claiming that a native Apple integration ran. The
deterministic slice, live Foundation Models probe, and host-compatible tests
pass locally. Apple Evaluations is supplemental and does not replace the
custom release gate.

## What this proves

- A trace can preserve the evidence needed to inspect an agent decision.
- Tool correctness and end-to-end completion are separate checks.
- An error path can be a passing result when the agent reports the failure honestly.
- A release gate can distinguish a passing result from a result that needs a rerun.

## What this does not prove

- The quality of Siri or Apple Intelligence as shipped by Apple.
- Performance of a Foundation Models deployment.
- Production-scale reliability.
- Safety for real personal data.

The current package already contains a native macOS app, real App Intents and
App Shortcut declarations, an App Entity/query, the live Foundation Models
adapter, an Apple Evaluations adapter, and the Xcode integration target.

## Interview path

Read [the five-minute walkthrough](docs/INTERVIEW_WALKTHROUGH.md) for the
recommended demonstration order. The validity fields in
[the report integration notes](docs/VALIDITY_INTEGRATION.md) explain why the
gate records repeat-run spread and decision consistency.
