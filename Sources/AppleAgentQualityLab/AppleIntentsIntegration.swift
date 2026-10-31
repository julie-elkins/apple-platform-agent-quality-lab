import Foundation

#if canImport(AppIntents)
import AppIntents

public struct FollowUpTaskEntity: AppEntity, Equatable, Sendable {
    public typealias ID = String

    public let id: String
    public let title: String
    public let status: String

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Follow-up task"
    )
    public static let defaultQuery = FollowUpTaskQuery()

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(status)"
        )
    }

    public init(id: String, title: String, status: String) {
        self.id = id
        self.title = title
        self.status = status
    }
}

public enum SyntheticFollowUpTaskCatalog {
    public static let tasks: [FollowUpTaskEntity] = [
        FollowUpTaskEntity(
            id: "task-001",
            title: "Review release evidence",
            status: "Open"
        ),
        FollowUpTaskEntity(
            id: "task-002",
            title: "Check retry policy notes",
            status: "Open"
        )
    ]

    public static func task(for identifier: String) -> FollowUpTaskEntity? {
        tasks.first { $0.id == identifier }
    }
}

public struct FollowUpTaskQuery: EntityStringQuery {
    public init() {}

    public func entities(for identifiers: [FollowUpTaskEntity.ID]) async throws -> [FollowUpTaskEntity] {
        identifiers.compactMap(SyntheticFollowUpTaskCatalog.task(for:))
    }

    public func suggestedEntities() async throws -> [FollowUpTaskEntity] {
        SyntheticFollowUpTaskCatalog.tasks
    }

    public func entities(matching string: String) async throws -> [FollowUpTaskEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return SyntheticFollowUpTaskCatalog.tasks
        }

        return SyntheticFollowUpTaskCatalog.tasks.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
                $0.status.localizedCaseInsensitiveContains(query)
        }
    }
}

public struct InspectFollowUpTaskIntent: AppIntent {
    public static let title: LocalizedStringResource = "Inspect Follow-Up Task"
    public static let description = IntentDescription(
        "Inspects a follow-up task from the synthetic task catalog."
    )

    @Parameter(title: "Follow-up task")
    public var task: FollowUpTaskEntity

    public init() {
        task = SyntheticFollowUpTaskCatalog.tasks[0]
    }

    public init(task: FollowUpTaskEntity) {
        self.task = task
    }

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(
            dialog: "The follow-up task \(task.title) is \(task.status.lowercased())."
        )
    }
}

public struct AppleAgentQualityLabShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateFollowUpIntent(),
            phrases: [
                "Create a follow-up task in \(.applicationName)"
            ],
            shortTitle: "Create follow-up",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: InspectFollowUpTaskIntent(),
            phrases: [
                "Inspect a follow-up task in \(.applicationName)"
            ],
            shortTitle: "Inspect task",
            systemImageName: "doc.text.magnifyingglass"
        )
    }
}
#endif
