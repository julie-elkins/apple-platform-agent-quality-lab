import Foundation

public struct EvaluationGate {
    public let minimumScore: Double
    public let maximumRepeatSpread: Double

    public init(minimumScore: Double = 0.8, maximumRepeatSpread: Double = 0.1) {
        self.minimumScore = minimumScore
        self.maximumRepeatSpread = maximumRepeatSpread
    }

    public func evaluate(
        scenario: Scenario,
        traces: [TraceEvent],
        response: String
    ) -> EvaluationResult {
        var failures: [String] = []
        let hasRequest = traces.contains { $0.kind == .request }
        let hasResponse = traces.contains { $0.kind == .modelResponse } && !response.isEmpty
        let hasEvaluator = traces.contains { $0.kind == .evaluator }

        let componentScore = hasResponse && hasEvaluator ? 1.0 : 0.0

        let toolCalls = traces.filter { $0.kind == .toolCall }
        let toolResults = traces.filter { $0.kind == .toolResult }
        let expectedToolWasUsed: Bool
        if let expectedTool = scenario.expectedTool {
            expectedToolWasUsed = toolCalls.contains { $0.name == expectedTool }
        } else {
            expectedToolWasUsed = true
        }
        let trajectoryScore = expectedToolWasUsed && (toolCalls.count == toolResults.count) ? 1.0 : 0.0

        let successfulAction = scenario.kind != .agenticAction ||
            traces.contains {
                $0.name == "app-intent.create-task.result" &&
                    $0.metadata["status"] == "success"
            }
        let honestRecovery = scenario.kind != .errorRecovery ||
            (response.contains("could not") && !response.contains("created the follow-up task."))
        let endToEndScore = hasRequest && successfulAction && honestRecovery ? 1.0 : 0.0

        if scenario.kind == .negativeControl {
            failures.append("negative_control_detected_wrong_tool")
        }

        if componentScore < minimumScore {
            failures.append("response_or_evaluator_evidence_missing")
        }
        if trajectoryScore < minimumScore {
            failures.append("tool_trajectory_mismatch")
        }
        if endToEndScore < minimumScore {
            failures.append("task_outcome_not_proven")
        }

        return EvaluationResult(
            scenarioID: scenario.id,
            componentScore: componentScore,
            trajectoryScore: trajectoryScore,
            endToEndScore: endToEndScore,
            failures: failures,
            evidenceCount: traces.count
        )
    }

    public func decide(
        results: [EvaluationResult],
        repeatedRunSpreads: [Double]
    ) -> ReleaseDecision {
        let minimumObservedScore = results
            .flatMap { [$0.componentScore, $0.trajectoryScore, $0.endToEndScore] }
            .min() ?? 0.0
        let spread = repeatedRunSpreads.max() ?? 0.0
        let passedScenarios = results.filter(\.passed).count

        let status: GateStatus
        let reason: String
        if results.isEmpty {
            status = .unavailable
            reason = "No scenarios produced evidence."
        } else if spread > maximumRepeatSpread {
            status = .rerunRequired
            reason = "Repeated runs moved more than the permitted variance threshold."
        } else if passedScenarios != results.count || minimumObservedScore < minimumScore {
            status = .fail
            reason = "At least one required evaluation family did not meet its threshold."
        } else {
            status = .pass
            reason = "All scenarios met the response, trajectory, and end-to-end thresholds."
        }

        return ReleaseDecision(
            status: status,
            reason: reason,
            passedScenarios: passedScenarios,
            totalScenarios: results.count,
            minimumObservedScore: minimumObservedScore,
            repeatedRunSpread: spread
        )
    }
}
