import XCTest
import AppIntentsTesting

@available(macOS 27.0, *)
final class AppleAgentQualityLabIntentTests: XCTestCase {
    func testCreateFollowUpIntentThroughSystemBoundary() async throws {
        let definitions = IntentDefinitions(
            bundleIdentifier: "com.julieelkins.apple-agent-quality-lab"
        )
        let intentDefinition = try XCTUnwrap(
            definitions.intents["CreateFollowUpIntent"]
        )
        let intent = intentDefinition.makeIntent(title: "Review release evidence")
        let result = try await intent.run()

        XCTAssertNotNil(result)
    }

    func testFollowUpEntityAndInspectIntentThroughSystemBoundary() async throws {
        let definitions = IntentDefinitions(
            bundleIdentifier: "com.julieelkins.apple-agent-quality-lab"
        )
        let taskDefinition = try XCTUnwrap(
            definitions.entities["FollowUpTaskEntity"]
        )
        let task = taskDefinition.makeReference(identifier: "task-001")
        let intentDefinition = try XCTUnwrap(
            definitions.intents["InspectFollowUpTaskIntent"]
        )
        let intent = intentDefinition.makeIntent(task: task)
        let result = try await intent.run()

        XCTAssertNotNil(result)
    }
}
