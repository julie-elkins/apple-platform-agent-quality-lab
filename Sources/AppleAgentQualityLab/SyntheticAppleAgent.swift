import Foundation

public struct SyntheticAppleAgent {
    public init() {}

    public func run(
        scenario: Scenario,
        startingSequence: Int = 1
    ) -> (response: String, traces: [TraceEvent]) {
        var sequence = startingSequence
        var traces: [TraceEvent] = []

        func append(
            _ kind: TraceEventKind,
            _ name: String,
            _ detail: String,
            _ metadata: [String: String] = [:]
        ) {
            traces.append(
                TraceEvent(
                    sequence: sequence,
                    kind: kind,
                    name: name,
                    detail: detail,
                    metadata: metadata
                )
            )
            sequence += 1
        }

        append(
            .request,
            "user.request",
            scenario.request,
            ["scenario": scenario.id, "kind": scenario.kind.rawValue]
        )

        switch scenario.kind {
        case .summarization:
            append(.modelResponse, "foundation-model.response", "Three decisions are due this week.")
            append(.evaluator, "rubric.grounding", "The response uses only the supplied notes.", ["score": "1.0"])
            return ("Three decisions are due this week.", traces)

        case .recommendation:
            append(.toolCall, "knowledge.search", "Search local synthetic project notes.", ["query": "active project risks"])
            append(.toolResult, "knowledge.search.result", "Two notes matched: release evidence and retry policy.")
            append(.modelResponse, "foundation-model.response", "Review release evidence before changing retry policy.")
            append(.evaluator, "rubric.relevance", "The recommendation is supported by the matched notes.", ["score": "1.0"])
            return ("Review release evidence before changing retry policy.", traces)

        case .agenticAction:
            append(.toolCall, "app-intent.create-task", "Create a follow-up task.", ["title": "Review release evidence"])
            append(.toolResult, "app-intent.create-task.result", "Created synthetic task task-001.", ["status": "success"])
            append(.modelResponse, "foundation-model.response", "Created the follow-up task.")
            append(.evaluator, "rubric.tool-correctness", "The requested action was selected and completed.", ["score": "1.0"])
            return ("Created the follow-up task.", traces)

        case .errorRecovery:
            append(.toolCall, "app-intent.create-task", "Create a follow-up task.", ["title": "Review release evidence"])
            append(.toolResult, "app-intent.create-task.result", "The synthetic task store rejected the request.", ["status": "error"])
            append(.modelResponse, "foundation-model.response", "I could not create the task, so I did not claim that it was created.")
            append(.evaluator, "rubric.error-recovery", "The response reports the failure without inventing success.", ["score": "1.0"])
            return ("I could not create the task, so I did not claim that it was created.", traces)

        case .negativeControl:
            append(.toolCall, "knowledge.search", "Search local synthetic project notes.", ["query": "create follow-up task"])
            append(.toolResult, "knowledge.search.result", "The notes do not create a task.", ["status": "success"])
            append(.modelResponse, "foundation-model.response", "Created the follow-up task.")
            append(.evaluator, "rubric.tool-correctness", "The action used the wrong tool and claimed completion.", ["score": "0.0"])
            return ("Created the follow-up task.", traces)
        }
    }
}
