# Design decisions

## Provider-neutral release slice with live model probe

- **Decided:** Keep deterministic synthetic scenarios as the release gate, and add an opt-in live Foundation Models mode.
- **Instead of:** Making every verification run depend on a variable on-device model.
- **Why:** The current SDK exposes FoundationModels and AppIntents, so a real Apple model probe is possible. The release decision still needs repeatable evidence, which the live model cannot guarantee by itself.
- **Costs if wrong:** The live mode may be unavailable on a particular machine and the AppIntentsTesting runtime check requires macOS 27.
- **Decided by:** Julie and Codex, based on the current build environment.

## One vertical path

- **Decided:** Keep request, trace, evaluator, and release gate in one small executable.
- **Instead of:** Starting with a dashboard, hosted service, or several horizontal infrastructure layers.
- **Why:** The Apple role emphasizes the end-to-end evaluation decision. A reviewer can verify one complete path faster than a collection of disconnected components.
- **Costs if wrong:** The first version does not demonstrate scale or multi-user operation.
- **Decided by:** Codex, based on interview signal and existing portfolio overlap.

## App-Intent system boundary

- **Decided:** Keep the local App-Intent-shaped scenario and add a separate Xcode
  `AppIntentsTesting` target for the real system-boundary check.
- **Instead of:** Treating a successful compile as proof that Siri, Shortcuts,
  or Spotlight executed the intent.
- **Why:** The release result must distinguish source/build evidence from runtime
  evidence. A false green result would undermine the whole project.
- **Costs if wrong:** Runtime verification is deferred until a macOS 27 machine
  is available, even though the test target now compiles.
- **Decided by:** Codex, based on evidence integrity.
