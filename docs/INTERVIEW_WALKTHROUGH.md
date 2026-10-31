# Five-minute Apple interview walkthrough

## What this demonstration proves

This project demonstrates an evaluation contract for an agentic workflow. An
evaluation contract is the explicit definition of what evidence must exist
before a result is accepted:

```text
request → tool call → tool result → model response → evaluator → release gate
```

The demonstration proves four things:

1. A normal workflow can pass a repeatable release gate.
2. A plausible-looking but incorrect tool path is rejected.
3. The failure is explained with a corrective recommendation.
4. Real local input can be evaluated without changing the stable baseline.

It does not claim to evaluate Siri or Apple Intelligence as shipped by Apple.

## Before the interview

Build and open the packaged app:

```text
cd apple-platform-agent-quality-lab
swift test
./scripts/build-app.sh
open "dist/Apple Platform Agent Quality Lab.app"
```

Use this safe demonstration file in Local Data Mode:

```text
README.md
```

The file is project documentation, not personal Apple data.

## The five-minute sequence

### 0:00–0:30 — State the problem

Say:

> “The question is not whether an AI answer looks good once. The question is
> whether there is enough evidence to release the workflow, including the tool
> path and the failure behavior.”

Point to the main window’s **Recommended demo flow**. Explain that the app is
split into two purposeful windows:

- Local Data Mode supplies a real, read-only local file.
- Quality Lab runs the controlled baseline and negative-control evaluations.

### 0:30–1:15 — Load real local input

Click **Open local data mode**.

In Local Data Mode:

1. Click **Load local Markdown or JSON**.
2. Select `README.md`.
3. Point out the source preview and the read-only explanation.
4. Click **Run local data evaluation**.

Say:

> “This is a bounded real-input path. The app reads the selected file locally,
> records the read as evidence, does not upload it, and does not write back to
> the source. This result is separate from the stable release gate.”

Point out the five evidence events:

- request;
- `local-file.read`;
- read result;
- model response;
- grounding evaluator.

### 1:15–1:35 — Return to the Quality Lab

Click **Return to Quality Lab**.

Say:

> “The handoff is explicit because the two windows have different jobs. Real
> input is useful for demonstrating the boundary; the controlled scenarios are
> what make the release decision reproducible.”

### 1:35–2:15 — Run the baseline

Click **Run baseline evaluation**.

Point out:

- `Release gate: PASS`;
- 5 scenarios;
- 5 passed;
- 0 failed;
- 0 expected failures.

The five normal scenarios are:

- summarization;
- grounded recommendation;
- App-Intent-shaped task creation;
- honest error recovery;
- confirmation required before a state-changing action.

Say:

> “PASS means the response evidence, tool trajectory, and end-to-end outcome
> all met the threshold. A trajectory is the ordered sequence of steps the
> agent took.”

### 2:15–2:45 — Show one trace

Use the detailed evidence trace to show one successful action and the honest
error-recovery case.

Emphasize:

> “A successful transport result is not automatically a successful task. The
> evaluator checks whether the correct tool was selected, whether the result
> proves completion, and whether the agent avoids claiming success after an
> error.”

Use the inner trace scrollbar if needed. Use the outer window scrollbar when
the full screen extends below the monitor.

### 2:45–3:35 — Run the negative control

Click **Run negative control — expected FAIL**.

Point out:

- `Release gate: FAIL`;
- 7 scenarios;
- 5 passed;
- 2 failed;
- 2 expected failures;
- the highlighted wrong-tool and unsupported-recommendation traces.

Say:

> “These are deliberately incorrect paths. The agent uses `knowledge.search`
> instead of the task-creation intent and also makes a recommendation without
> supporting evidence. The gate rejects both because the observed trajectory
> and grounding evidence do not support the claims.”

Read the remediation panel:

> “Route task creation to `CreateFollowUpIntent` and require a successful tool
> result before claiming completion.”

Then explain the boundary:

> “The evaluator recommends remediation; it does not silently change the
> application. That preserves evidence of the failure and keeps the fix under
> human or controlled-system review.”

### 3:35–4:05 — Restore the clean baseline

Click **Run baseline again — restore PASS**.

Point out:

- `Release gate: PASS`;
- 5 scenarios;
- 5 passed;
- run history: baseline `PASS` → negative control `FAIL` as expected →
  baseline `PASS restored`.

Say:

> “This PASS is a fresh five-scenario run. It did not repair the failed run;
> the intentionally bad scenario was simply not included. The history keeps
> both facts visible.”

### 4:05–5:00 — Explain the Apple boundary and limitations

Close with:

> “The project also contains real App Intents, an App Entity/query, two App
> Shortcuts, an optional Foundation Models path, and an Apple Evaluations
> adapter. The custom deterministic gate remains authoritative because live
> model output and supplemental platform metrics must not silently decide
> whether the evaluator itself is healthy.”

State the environment limitation plainly:

> “This laptop is on macOS 26.7.2. The native `AppIntentsTesting` and Apple
> Evaluations runtime paths require macOS 27, so the project has local package
> evidence and compile evidence here, while the full native runtime test needs
> a compatible macOS 27 machine.”

Finish with:

> “The project demonstrates the evaluation contract, evidence capture, failure
> handling, repeatability, and release decision. It does not claim production
> reliability, Siri quality, or safety for unrestricted personal data.”

## Bridge the demo to your experience

If the interviewer asks how this project connects to your background, use this
short bridge:

> “My background is in building the instruments and review systems that tell us
> whether a technical capability has actually been demonstrated. In AWS
> Certification, that has meant blueprints, assessment quality, technical
> review, and calibrated human judgment. More recently, I have applied the same
> discipline to AI workflows: define the contract, capture the evidence,
> inspect the trajectory, test the evaluator, and make the release decision
> explainable.”

Then make the boundary explicit:

> “I am not presenting myself as a model researcher. I am presenting myself as
> an evaluation and quality-gate engineer who understands AI systems well
> enough to measure them, expose failure, and stop a system from reporting
> success when it did not verify the result.”

This bridge matters because the demo is evidence of how you work; it is not
intended to replace the experience discussion. The strongest story is the
combination of your assessment background, your AI evaluation work, and the
artifact that makes the reasoning inspectable.

## Likely follow-up questions

### Why keep the baseline deterministic?

Deterministic means the same scenario produces the same expected result. That
makes a gate failure attributable to the workflow or evaluator rather than
random model variation.

### Why include a negative control?

A negative control is a deliberately broken case used to check that the
evaluator can detect failure. A system that only passes good examples has not
shown that its gate is sensitive to bad behavior.

### Why not connect directly to Reminders or Calendar?

The interview artifact needs a visible, reproducible input boundary without
requiring personal permissions or exposing private data. A read-only local
file demonstrates the boundary first; production connectors would add
authorization, privacy, indexing, and system-integration work.

### What would you add for production?

I would add a versioned evaluation set, controlled model and tool fixtures,
privacy-preserving telemetry, regression comparison across releases, explicit
authorization for system data, and a macOS 27 runtime test lane for the native
Apple evaluation APIs.

### What should not be claimed?

Do not say that the project evaluates Siri itself, proves Apple Intelligence
quality, or establishes production-scale reliability. Say that it demonstrates
the evidence and release-gate design those systems require.
