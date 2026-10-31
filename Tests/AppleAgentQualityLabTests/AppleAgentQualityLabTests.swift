import XCTest
@testable import AppleAgentQualityLab

final class AppleAgentQualityLabTests: XCTestCase {
    func testFollowUpTaskQueryResolvesSeededEntity() async throws {
        let query = FollowUpTaskQuery()

        let suggestions = try await query.suggestedEntities()
        XCTAssertEqual(suggestions.map(\.id), ["task-001", "task-002"])

        let resolved = try await query.entities(for: ["task-001", "missing-task"])
        XCTAssertEqual(resolved.map(\.title), ["Review release evidence"])

        let matches = try await query.entities(matching: "retry")
        XCTAssertEqual(matches.map(\.id), ["task-002"])
    }

    func testAppShortcutsExposeCreateAndInspectPaths() {
        let shortcuts = AppleAgentQualityLabShortcuts.appShortcuts
        XCTAssertEqual(shortcuts.count, 2)
    }

    func testAppleEvaluationsReportsCurrentAvailability() async {
        let scenario = demoScenarios()[0]
        let result = EvaluationResult(
            scenarioID: scenario.id,
            componentScore: 1.0,
            trajectoryScore: 1.0,
            endToEndScore: 1.0,
            failures: [],
            evidenceCount: 2
        )

        let report = await AppleEvaluationsAdapter.evaluate(
            scenario: scenario,
            result: result
        )

        if #available(macOS 27.0, *) {
            XCTAssertEqual(report.availability, .available)
        } else {
            XCTAssertEqual(report.availability, .unavailable)
        }
    }

    func testLocalMarkdownImporterProducesReadOnlyEvaluationEvidence() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("md")
        let markdown = """
        # Release review
        Decide whether to rerun the evidence check.
        Confirm the retry policy before publishing.
        """
        try markdown.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let document = try LocalDataImporter.load(url: url)
        XCTAssertEqual(document.sourceName, url.lastPathComponent)
        XCTAssertEqual(document.lineCount, 3)
        XCTAssertTrue(document.content.contains("Release review"))

        let scenario = localDataScenario(sourceName: document.sourceName)
        let run = LocalDataAgent().run(document: document)
        let result = EvaluationGate().evaluate(
            scenario: scenario,
            traces: run.traces,
            response: run.response
        )

        XCTAssertTrue(result.passed)
        XCTAssertEqual(run.traces.filter { $0.name == "local-file.read" }.count, 1)
        XCTAssertEqual(
            run.traces.first { $0.name == "local-file.read" }?.metadata["readOnly"],
            "true"
        )
    }

    func testLocalJSONImporterNormalizesStructuredInput() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let json = #"{"decision":"review evidence","owner":"CTA"}"#
        try json.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let document = try LocalDataImporter.load(url: url)
        XCTAssertTrue(document.content.contains("\"decision\""))
        XCTAssertTrue(document.content.contains("\"review evidence\""))
    }
}
