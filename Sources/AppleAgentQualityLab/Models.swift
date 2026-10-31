import Foundation

public enum ScenarioKind: String, Codable, CaseIterable, Sendable {
    case summarization
    case recommendation
    case agenticAction
    case errorRecovery
    case confirmationRequired
    case unsupportedRecommendation
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

public enum EvidenceStatus: String, Codable, Sendable {
    case passed
    case failed
    case blocked
    case notEvaluated = "not_evaluated"
    case notApplicable = "not_applicable"
    case rerunRequired = "rerun_required"
    case unavailable
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
    public let status: EvidenceStatus
    public let evaluatorValid: Bool

    public init(
        scenarioID: String,
        componentScore: Double,
        trajectoryScore: Double,
        endToEndScore: Double,
        failures: [String],
        evidenceCount: Int,
        status: EvidenceStatus? = nil,
        evaluatorValid: Bool = true
    ) {
        self.scenarioID = scenarioID
        self.componentScore = componentScore
        self.trajectoryScore = trajectoryScore
        self.endToEndScore = endToEndScore
        self.failures = failures
        self.evidenceCount = evidenceCount
        self.status = status ?? (failures.isEmpty ? .passed : .failed)
        self.evaluatorValid = evaluatorValid
    }

    public var passed: Bool {
        status == .passed &&
            evaluatorValid &&
            failures.isEmpty &&
            componentScore >= 0.8 &&
            trajectoryScore >= 0.8 &&
            endToEndScore >= 0.8
    }
}

public struct DimensionEvidence: Codable, Equatable, Sendable {
    public let status: EvidenceStatus
    public let rationale: String
    public let score: Double?

    public init(status: EvidenceStatus, rationale: String, score: Double? = nil) {
        self.status = status
        self.rationale = rationale
        self.score = score
    }
}

public struct ReleaseContract: Codable, Equatable, Sendable {
    public let blockingChecks: [String]
    public let informativeChecks: [String]
    public let requiredEvidence: [String]
    public let highRiskSlices: [String]
    public let evaluatorUnavailableStatus: EvidenceStatus
    public let humanApprovalRequired: Bool
    public let humanApprovalState: String
    public let owner: String

    public init(
        blockingChecks: [String],
        informativeChecks: [String],
        requiredEvidence: [String],
        highRiskSlices: [String],
        evaluatorUnavailableStatus: EvidenceStatus,
        humanApprovalRequired: Bool,
        humanApprovalState: String,
        owner: String
    ) {
        self.blockingChecks = blockingChecks
        self.informativeChecks = informativeChecks
        self.requiredEvidence = requiredEvidence
        self.highRiskSlices = highRiskSlices
        self.evaluatorUnavailableStatus = evaluatorUnavailableStatus
        self.humanApprovalRequired = humanApprovalRequired
        self.humanApprovalState = humanApprovalState
        self.owner = owner
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
    public let reportVocabularyRevision: String
    public let frameworkAvailability: FrameworkAvailability
    public let scenarios: [Scenario]
    public let traces: [String: [TraceEvent]]
    public let evaluations: [EvaluationResult]
    public let releaseContract: ReleaseContract
    public let dimensions: [String: DimensionEvidence]
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
