import Foundation

#if canImport(AppIntents)
import AppIntents

public struct CreateFollowUpIntent: AppIntent {
    public static let title: LocalizedStringResource = "Create Follow-Up Task"
    public static let description = IntentDescription("Creates a follow-up task in the synthetic task store.")

    @Parameter(title: "Task title")
    public var title: String

    public init() {
        title = "Review release evidence"
    }

    public init(title: String) {
        self.title = title
    }

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Created the follow-up task: \(title).")
    }
}
#endif
