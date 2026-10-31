import Foundation

#if canImport(Evaluations)
import Evaluations
#endif

public enum AppleEvaluationsAvailability: String, Codable, Equatable, Sendable {
    case available
    case unavailable
}

public struct AppleEvaluationMetricResult: Codable, Equatable, Sendable {
    public let name: String
    public let value: Double?
    public let passed: Bool
    public let rationale: String?

    public init(name: String, value: Double?, passed: Bool, rationale: String?) {
        self.name = name
        self.value = value
        self.passed = passed
        self.rationale = rationale
    }
}

public struct AppleScenarioEvaluation: Codable, Equatable, Sendable {
    public let scenarioID: String
    public let availability: AppleEvaluationsAvailability
    public let metrics: [AppleEvaluationMetricResult]
    public let note: String

    public init(
        scenarioID: String,
        availability: AppleEvaluationsAvailability,
        metrics: [AppleEvaluationMetricResult],
        note: String
    ) {
        self.scenarioID = scenarioID
        self.availability = availability
        self.metrics = metrics
        self.note = note
    }
}

public struct AppleEvaluationsSummary: Codable, Equatable, Sendable {
    public let availability: AppleEvaluationsAvailability
    public let passedMetrics: Int
    public let totalMetrics: Int
    public let scenarios: [AppleScenarioEvaluation]
    public let note: String

    public init(
        availability: AppleEvaluationsAvailability,
        passedMetrics: Int,
        totalMetrics: Int,
        scenarios: [AppleScenarioEvaluation],
        note: String
    ) {
        self.availability = availability
        self.passedMetrics = passedMetrics
        self.totalMetrics = totalMetrics
        self.scenarios = scenarios
        self.note = note
    }
}

public enum AppleEvaluationsAdapter {
    public static func evaluate(
        scenario: Scenario,
        result: EvaluationResult
    ) async -> AppleScenarioEvaluation {
        #if canImport(Evaluations)
        if #available(macOS 27.0, *) {
            return await evaluateWithAppleFramework(
                scenario: scenario,
                result: result
            )
        }
        #endif

        return AppleScenarioEvaluation(
            scenarioID: scenario.id,
            availability: .unavailable,
            metrics: [],
            note: "Apple Evaluations requires macOS 27.0; the custom gate remains authoritative."
        )
    }

    public static func summarize(
        scenarios: [AppleScenarioEvaluation]
    ) -> AppleEvaluationsSummary {
        let metrics = scenarios.flatMap(\.metrics)
        let available = scenarios.contains {
            $0.availability == .available
        }

        return AppleEvaluationsSummary(
            availability: available ? .available : .unavailable,
            passedMetrics: metrics.filter(\.passed).count,
            totalMetrics: metrics.count,
            scenarios: scenarios,
            note: available
                ? "Apple Evaluations metrics are supplemental; the custom release gate remains authoritative."
                : "Apple Evaluations was not runtime-available; the custom release gate remains authoritative."
        )
    }

    #if canImport(Evaluations)
    @available(macOS 27.0, *)
    private static func evaluateWithAppleFramework(
        scenario: Scenario,
        result: EvaluationResult
    ) async -> AppleScenarioEvaluation {
        struct EvaluationValue: Codable, Sendable, Equatable {
            let component: Double
            let trajectory: Double
            let endToEnd: Double
        }

        let expected = EvaluationValue(
            component: result.componentScore,
            trajectory: result.trajectoryScore,
            endToEnd: result.endToEndScore
        )
        let sample = Evaluations.ModelSample<EvaluationValue>(
            prompt: scenario.request,
            expected: expected
        )
        let evaluator = Evaluations.Evaluator<Evaluations.ModelSample<EvaluationValue>> {
            input,
            subject in
            guard let expectedValue = input.expected else {
                return Evaluations.Metric("evaluation_recorded").failing(
                    rationale: "The sample did not contain expected score evidence."
                )
            }

            let matches = subject.value == expectedValue
            return Evaluations.Metric("evaluation_recorded").scoring(
                matches ? 1.0 : 0.0,
                rationale: matches
                    ? "The Apple Evaluations subject matched the release-gate score vector."
                    : "The Apple Evaluations subject did not match the release-gate score vector."
            )
        }

        do {
            let metrics = try await evaluator.metrics(
                subject: Evaluations.ModelSubject(value: expected),
                input: sample
            )
            return AppleScenarioEvaluation(
                scenarioID: scenario.id,
                availability: .available,
                metrics: metrics.map {
                    AppleEvaluationMetricResult(
                        name: $0.name,
                        value: $0.doubleValue,
                        passed: $0.doubleValue == 1.0,
                        rationale: $0.rationale
                    )
                },
                note: "Evaluated with Apple's Evaluations.Metric and Evaluator APIs; the custom gate remains authoritative."
            )
        } catch {
            return AppleScenarioEvaluation(
                scenarioID: scenario.id,
                availability: .available,
                metrics: [
                    AppleEvaluationMetricResult(
                        name: "evaluation_runtime",
                        value: 0.0,
                        passed: false,
                        rationale: "Apple Evaluations returned an error: \(error.localizedDescription)"
                    )
                ],
                note: "Apple Evaluations was linked but returned a runtime error."
            )
        }
    }
    #endif
}
