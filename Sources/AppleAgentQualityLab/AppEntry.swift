import Foundation

@main
struct AppleAgentQualityLabMain {
    static func main() async throws {
        let launchedFromAppBundle = Bundle.main.bundleURL.pathExtension == "app"
        if CommandLine.arguments.contains("--gui") || launchedFromAppBundle {
            #if canImport(AppKit)
            if #available(macOS 14.0, *) {
                MacOSAppLauncher.run()
                return
            }
            #endif
            print("GUI mode is unavailable in this build.")
            Foundation.exit(1)
        }

        let includeNegativeControl = CommandLine.arguments.contains("--negative-control")
        var scenarios = demoScenarios()
        if includeNegativeControl {
            scenarios.append(negativeControlScenario())
        }
        let useLiveFoundationModel = CommandLine.arguments.contains("--live-foundation-model")
        let agent = SyntheticAppleAgent()
        let gate = EvaluationGate()
        var traces: [String: [TraceEvent]] = [:]
        var results: [EvaluationResult] = []
        var repeatResults: [EvaluationResult] = []
        var appleScenarioEvaluations: [AppleScenarioEvaluation] = []

        for scenario in scenarios {
            var run = agent.run(scenario: scenario)

            #if canImport(FoundationModels)
            if useLiveFoundationModel && scenario.kind == .summarization {
                if #available(macOS 26.0, *) {
                    let notes = """
                    Release evidence must be reviewed before the retry policy changes.
                    The task store is unavailable in the failure scenario.
                    """
                    do {
                        let response = try await AppleFoundationModelAgent().summarize(notes: notes)
                        run = (
                            response: response,
                            traces: run.traces.map { event in
                                guard event.name == "foundation-model.response" else {
                                    return event
                                }
                                return TraceEvent(
                                    sequence: event.sequence,
                                    kind: event.kind,
                                    name: event.name,
                                    detail: response,
                                    metadata: [
                                        "provider": "Apple Foundation Models",
                                        "mode": "live"
                                    ]
                                )
                            }
                        )
                    } catch {
                        print("Live Foundation Models run unavailable; using synthetic fallback: \(error)")
                    }
                }
            }
            #else
            if useLiveFoundationModel {
                print("Live Foundation Models mode unavailable in this build; using synthetic fallback.")
            }
            #endif

            traces[scenario.id] = run.traces
            let result = gate.evaluate(
                scenario: scenario,
                traces: run.traces,
                response: run.response
            )
            results.append(result)
            appleScenarioEvaluations.append(
                await AppleEvaluationsAdapter.evaluate(
                    scenario: scenario,
                    result: result
                )
            )

            let repeatRun = agent.run(scenario: scenario)
            repeatResults.append(
                gate.evaluate(
                    scenario: scenario,
                    traces: repeatRun.traces,
                    response: repeatRun.response
                )
            )
        }

        let primaryScores = results.flatMap {
            [$0.componentScore, $0.trajectoryScore, $0.endToEndScore]
        }
        let repeatedScores = repeatResults.flatMap {
            [$0.componentScore, $0.trajectoryScore, $0.endToEndScore]
        }
        let repeatedRunSpread = zip(primaryScores, repeatedScores)
            .map { abs($0 - $1) }
            .max() ?? 0.0
        let decision = gate.decide(
            results: results,
            repeatedRunSpreads: [repeatedRunSpread]
        )
        let repeatDecision = gate.decide(
            results: repeatResults,
            repeatedRunSpreads: [repeatedRunSpread]
        )
        let validity = ValiditySummary(
            evaluationCount: results.count,
            repeatRunCount: 2,
            repeatedRunSpread: repeatedRunSpread,
            allowedSpread: gate.maximumRepeatSpread,
            decisionConsistency: decision.status == repeatDecision.status,
            interpretation: repeatedRunSpread <= gate.maximumRepeatSpread
                ? "The two deterministic administrations produced the same score vector within the allowed spread."
                : "The repeated administration moved beyond the allowed spread; the result requires another run."
        )

        precondition(results.count == scenarios.count, "Every scenario must produce an evaluation result.")
        if !includeNegativeControl {
            precondition(results.allSatisfy(\.passed), "The deterministic verification scenarios must pass.")
            precondition(decision.status == .pass, "The deterministic release gate must pass.")
        }
        precondition(
            results.contains {
                $0.scenarioID == "honest-error-recovery" &&
                    $0.failures.isEmpty
            },
            "The honest error-recovery scenario must remain covered."
        )

        let report = RunReport(
            product: "Apple Platform Agent Quality Lab",
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            frameworkAvailability: AppleFrameworkAvailabilityProvider.current,
            scenarios: scenarios,
            traces: traces,
            evaluations: results,
            validity: validity,
            decision: decision,
            appleEvaluations: AppleEvaluationsAdapter.summarize(
                scenarios: appleScenarioEvaluations
            )
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let reportData = try encoder.encode(report)
        let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("apple-agent-quality-report.json")
        try reportData.write(to: outputURL)

        print("Apple Platform Agent Quality Lab")
        print("Frameworks: \(report.frameworkAvailability.note)")
        let mode = useLiveFoundationModel
            ? "live Foundation Models where available"
            : (includeNegativeControl ? "deterministic negative control" : "deterministic synthetic")
        print("Mode: \(mode)")
        print("Scenarios: \(decision.passedScenarios)/\(decision.totalScenarios) passed")
        print("Minimum observed score: \(String(format: "%.2f", decision.minimumObservedScore))")
        print("Release gate: \(decision.status.rawValue)")
        print("Reason: \(decision.reason)")
        print("Apple Evaluations: \(report.appleEvaluations.availability.rawValue.uppercased())")
        print("Report: \(outputURL.path)")

        if decision.status != .pass {
            Foundation.exit(1)
        }
    }
}
