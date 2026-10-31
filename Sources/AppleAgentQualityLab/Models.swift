import Foundation

public enum ScenarioKind: String, Codable, CaseIterable, Sendable {
    case summarization
    case recommendation
    case agenticAction
    case errorRecovery
    case negativeControl
}

public enum TraceEventKind: String, Codable {
    case request
    case modelResponse
    case toolCall
    case toolResult
    case evaluator
    case decision
}

public struct TraceEvent: Codable, Equatable {
    public let sequence: Int
    public let kind: TraceEventKind
    public let name: String
    public let detail: String
    public let metadata: [String: String]

    public init(
        sequence: Int,
        kind: TraceEventKind,
        name: String,
        detail: String,
        metadata: [String: String] = [:]
    ) {
        self.sequence = sequence
        self.kind = kind
        self.name = name
        self.detail = detail
        self.metadata = metadata
    }
}

public struct Scenario: Codable, Equatable, Sendable {
    public let id: String
    public let kind: ScenarioKind
    public let request: String
    public let expectedTool: String?
    public let expectedOutcome: String

    public init(
        id: String,
        kind: ScenarioKind,
        request: String,
        expectedTool: String?,
        expectedOutcome: String
    ) {
        self.id = id
        self.kind = kind
        self.request = request
        self.expectedTool = expectedTool
        self.expectedOutcome = expectedOutcome
    }
}

public struct EvaluationResult: Codable, Equatable, Sendable {
    public let scenarioID: String
    public let componentScore: Double
    public let trajectoryScore: Double
    public let endToEndScore: Double
    public let failures: [String]
    public let evidenceCount: Int

    public var passed: Bool {
        failures.isEmpty &&
            componentScore >= 0.8 &&
            trajectoryScore >= 0.8 &&
            endToEndScore >= 0.8
    }
}

public enum GateStatus: String, Codable {
    case pass = "PASS"
    case fail = "FAIL"
    case rerunRequired = "RERUN REQUIRED"
    case unavailable = "UNAVAILABLE"
}

public struct ReleaseDecision: Codable, Equatable {
    public let status: GateStatus
    public let reason: String
    public let passedScenarios: Int
    public let totalScenarios: Int
    public let minimumObservedScore: Double
    public let repeatedRunSpread: Double
}

public struct RunReport: Codable, Equatable {
    public let product: String
    public let generatedAt: String
    public let frameworkAvailability: FrameworkAvailability
    public let scenarios: [Scenario]
    public let traces: [String: [TraceEvent]]
    public let evaluations: [EvaluationResult]
    public let validity: ValiditySummary
    public let decision: ReleaseDecision
    public let appleEvaluations: AppleEvaluationsSummary
}

public struct ValiditySummary: Codable, Equatable {
    public let evaluationCount: Int
    public let repeatRunCount: Int
    public let repeatedRunSpread: Double
    public let allowedSpread: Double
    public let decisionConsistency: Bool
    public let interpretation: String
}

public struct FrameworkAvailability: Codable, Equatable {
    public let foundationModels: Bool
    public let appIntents: Bool
    public let appIntentsTesting: Bool
    public let evaluations: Bool
    public let note: String
}
