# Xcode and AppIntentsTesting integration

`AppIntentsTesting` is Apple's integration-testing framework for exercising
App Intents through the same system boundary used by Siri, Shortcuts, and
Spotlight. It runs in an XCUITest bundle, so the test runner and the app need
to be added to a full Xcode project with matching signing configuration.

The repository now includes a full Xcode project with:

- `CreateFollowUpIntent` is implemented in the Swift package.
- `InspectFollowUpTaskIntent` accepts a real `FollowUpTaskEntity`.
- `AppleAgentQualityLabShortcuts` publishes create and inspect shortcuts.
- The native app target is buildable.
- App Intents metadata is extracted by Xcode.
- `AppleAgentQualityLabIntentTests` is a separate system-boundary test target.

## Current execution constraint

The installed Xcode version exposes `AppIntentsTesting` and `Evaluations` as
macOS 27.0 APIs. This Mac is currently running macOS 26.7.1, so the test target
can be compiled but cannot honestly be claimed as runtime-verified here until
the Mac runs macOS 27 or the test is run on a compatible machine.

The test should verify that the create intent is discoverable by name, accepts
the title parameter, and returns the expected dialog. It should also resolve
`task-001` as a `FollowUpTaskEntity`, invoke `InspectFollowUpTaskIntent`, and
return its dialog. It deliberately does not import the app's implementation
module; that separation is the point of the system-boundary test.

## What counts as passing

- The intent is found by its registered name.
- The parameter is converted and delivered correctly.
- The entity identifier is resolved to the expected task.
- The App Shortcut and entity metadata are extracted by Xcode.
- The intent executes in the app process.
- The result reports the requested task title.
- A deliberately invalid or unavailable action produces a refusal rather than
  a success claim.
