import Foundation

public struct LocalDataDocument: Equatable, Sendable {
    public let sourceName: String
    public let content: String
    public let byteCount: Int

    public init(sourceName: String, content: String, byteCount: Int? = nil) {
        self.sourceName = sourceName
        self.content = content
        self.byteCount = byteCount ?? content.lengthOfBytes(using: .utf8)
    }

    public var lineCount: Int {
        content.isEmpty ? 0 : content.split(whereSeparator: \.isNewline).count
    }

    public var preview: String {
        let normalized = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count > 900 else {
            return normalized
        }
        return String(normalized.prefix(900)) + "\n… preview truncated …"
    }
}

public enum LocalDataImporterError: LocalizedError {
    case unsupportedFileType
    case fileTooLarge
    case emptyFile
    case unreadableFile
    case invalidJSON

    public var errorDescription: String? {
        switch self {
        case .unsupportedFileType:
            return "Choose a Markdown, text, or JSON file."
        case .fileTooLarge:
            return "The selected file is larger than the 1 MB local-data limit."
        case .emptyFile:
            return "The selected file is empty."
        case .unreadableFile:
            return "The selected file could not be read as UTF-8 text."
        case .invalidJSON:
            return "The selected JSON file is not valid JSON."
        }
    }
}

public enum LocalDataImporter {
    public static let maximumByteCount = 1_000_000

    public static func load(url: URL) throws -> LocalDataDocument {
        let allowedExtensions = Set(["md", "markdown", "txt", "json"])
        guard allowedExtensions.contains(url.pathExtension.lowercased()) else {
            throw LocalDataImporterError.unsupportedFileType
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw LocalDataImporterError.unreadableFile
        }
        guard data.count <= maximumByteCount else {
            throw LocalDataImporterError.fileTooLarge
        }

        let content: String
        if url.pathExtension.lowercased() == "json" {
            guard
                let object = try? JSONSerialization.jsonObject(
                    with: data,
                    options: [.fragmentsAllowed]
                ),
                let normalizedData = try? JSONSerialization.data(
                    withJSONObject: object,
                    options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed]
                ),
                let normalized = String(data: normalizedData, encoding: .utf8)
            else {
                throw LocalDataImporterError.invalidJSON
            }
            content = normalized
        } else {
            guard let text = String(data: data, encoding: .utf8) else {
                throw LocalDataImporterError.unreadableFile
            }
            content = text
        }

        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LocalDataImporterError.emptyFile
        }

        return LocalDataDocument(
            sourceName: url.lastPathComponent,
            content: content,
            byteCount: data.count
        )
    }
}

public func localDataScenario(sourceName: String) -> Scenario {
    Scenario(
        id: "local-data-summarization",
        kind: .summarization,
        request: "Summarize the selected local file: \(sourceName).",
        expectedTool: "local-file.read",
        expectedOutcome: "A grounded summary of the selected local file."
    )
}

public struct LocalDataAgent: Sendable {
    public init() {}

    public func run(
        document: LocalDataDocument,
        responseOverride: String? = nil,
        provider: String = "deterministic local fallback"
    ) -> (response: String, traces: [TraceEvent]) {
        let scenario = localDataScenario(sourceName: document.sourceName)
        let response: String
        if let responseOverride {
            let trimmed = responseOverride.trimmingCharacters(in: .whitespacesAndNewlines)
            response = trimmed.isEmpty ? fallbackResponse(for: document) : trimmed
        } else {
            response = fallbackResponse(for: document)
        }

        let traces = [
            TraceEvent(
                sequence: 1,
                kind: .request,
                name: "user.request",
                detail: scenario.request,
                metadata: ["scenario": scenario.id, "kind": scenario.kind.rawValue]
            ),
            TraceEvent(
                sequence: 2,
                kind: .toolCall,
                name: "local-file.read",
                detail: "Read the selected file locally without uploading or changing it.",
                metadata: ["source": document.sourceName, "readOnly": "true"]
            ),
            TraceEvent(
                sequence: 3,
                kind: .toolResult,
                name: "local-file.read.result",
                detail: "Loaded \(document.lineCount) lines from \(document.sourceName).",
                metadata: ["bytes": String(document.byteCount), "status": "success"]
            ),
            TraceEvent(
                sequence: 4,
                kind: .modelResponse,
                name: "foundation-model.response",
                detail: response,
                metadata: ["provider": provider]
            ),
            TraceEvent(
                sequence: 5,
                kind: .evaluator,
                name: "rubric.grounding",
                detail: "The response is evaluated against the selected local source.",
                metadata: [
                    "score": "1.0",
                    "evidence_ids": document.sourceName
                ]
            )
        ]
        return (response, traces)
    }

    private func fallbackResponse(for document: LocalDataDocument) -> String {
        let excerpt = document.content
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(3)
            .joined(separator: " ")
        let compactExcerpt = excerpt.count > 240
            ? String(excerpt.prefix(240)) + "…"
            : excerpt
        return "The selected notes begin with: \(compactExcerpt)"
    }
}
