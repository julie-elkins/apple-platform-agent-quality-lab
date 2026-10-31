import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(macOS 26.0, *)
public struct AppleFoundationModelAgent {
    public init() {}

    public func summarize(notes: String) async throws -> String {
        let session = LanguageModelSession(
            instructions: """
            You summarize user-provided project notes. Use only the notes supplied by the user.
            Do not invent facts or claim actions were taken. Return one concise, grounded
            sentence naming the most important decisions or follow-ups in the notes.
            """
        )
        let response = try await session.respond(
            to: "Summarize the open decisions in these notes:\n\(notes)"
        )
        return response.content
    }
}
#endif
