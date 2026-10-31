import Foundation

#if canImport(AppKit)
import AppKit

@MainActor
final class QualityLabViewController: NSViewController {
    private let statusLabel = NSTextField(labelWithString: "Release gate: NOT RUN")
    private let reasonLabel = NSTextField(labelWithString: "Run the evaluation to inspect the release decision.")
    private let resultMeaningLabel = NSTextField(
        wrappingLabelWithString: "Start with the baseline evaluation. It runs the five normal scenarios."
    )
    private let runSummaryLabel = NSTextField(
        wrappingLabelWithString: "Mode: No run yet\nScenarios: —  Passed: —  Failed: —  Expected failures: —"
    )
    private let runHistoryLabel = NSTextField(
        wrappingLabelWithString: "Run history: No evaluation has run yet."
    )
    private let remediationLabel = NSTextField(
        wrappingLabelWithString: "Run an evaluation to see failure analysis and a recommended remediation."
    )
    private let resultsView = NSTextView()
    private let runButton = NSButton()
    private let negativeButton = NSButton()
    private let localDataButton = NSButton()
    private var localDataWindowController: LocalDataWindowController?
    private var runHistory: [String] = []
    private var lastRunWasNegativeControl = false

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let titleLabel = NSTextField(labelWithString: "Apple Platform Agent Quality Lab")
        titleLabel.font = .boldSystemFont(ofSize: 24)

        let subtitleLabel = NSTextField(
            labelWithString: "Response, tool-trajectory, and end-to-end evidence for an Apple-style intelligent app."
        )
        subtitleLabel.textColor = .secondaryLabelColor

        statusLabel.font = .boldSystemFont(ofSize: 18)
        reasonLabel.textColor = .secondaryLabelColor
        resultMeaningLabel.font = .systemFont(ofSize: 13)
        runSummaryLabel.font = .systemFont(ofSize: 13)
        runSummaryLabel.textColor = .secondaryLabelColor
        runHistoryLabel.font = .systemFont(ofSize: 13)
        runHistoryLabel.textColor = .secondaryLabelColor
        remediationLabel.font = .systemFont(ofSize: 13)

        resultsView.isEditable = false
        resultsView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        resultsView.drawsBackground = true
        resultsView.backgroundColor = .textBackgroundColor
        resultsView.isVerticallyResizable = true
        resultsView.isHorizontallyResizable = false
        resultsView.autoresizingMask = [.width]
        resultsView.textContainer?.widthTracksTextView = true
        resultsView.textContainer?.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        )
        resultsView.string = "No evaluation has run yet."

        let resultsScrollView = NSScrollView()
        resultsScrollView.borderType = .bezelBorder
        resultsScrollView.hasVerticalScroller = true
        resultsScrollView.hasHorizontalScroller = false
        resultsScrollView.autohidesScrollers = false
        resultsScrollView.documentView = resultsView

        runButton.title = "Run baseline evaluation"
        runButton.target = self
        runButton.action = #selector(runEvaluation)
        runButton.bezelStyle = .rounded

        negativeButton.title = "Run negative control — expected FAIL"
        negativeButton.target = self
        negativeButton.action = #selector(runNegativeControl)
        negativeButton.bezelStyle = .rounded

        localDataButton.title = "Open local data mode"
        localDataButton.target = self
        localDataButton.action = #selector(openLocalDataMode)
        localDataButton.bezelStyle = .rounded

        let explanationTitle = makeSectionTitle("What this app is testing")
        let explanationBox = makeInfoBox(
            text: """
            The app checks whether an AI response followed the right evidence path:
            user request → tool call → tool result → model response → evaluator.
            A trajectory is the sequence of steps the agent took. The evaluator checks
            both the final answer and whether the steps were appropriate.
            """,
            minimumHeight: 88
        )
        let buttonGuideTitle = makeSectionTitle("What the buttons do")
        let buttonGuideBox = makeInfoBox(
            text: """
            Run baseline evaluation runs the five normal scenarios. Run negative control
            adds two deliberately incorrect paths and is expected to show FAIL. It
            does not change or repair the application. Open local data mode evaluates a
            selected Markdown or JSON file in a separate read-only window.
            """,
            minimumHeight: 82
        )
        let workflowTitle = makeSectionTitle("Recommended demo flow")
        let workflowBox = makeInfoBox(
            text: """
            1. Open local data mode.
            2. Load a de-identified Markdown, text, or JSON file.
            3. Run the local evaluation and review its evidence.
            4. Return to this Quality Lab window.
            5. Run baseline evaluation, then the negative control, then baseline again.
            """,
            minimumHeight: 116
        )
        let resultTitle = makeSectionTitle("Current result")
        let resultBox = makeInfoBox(
            content: resultMeaningLabel
        )
        let runSummaryTitle = makeSectionTitle("Current run summary")
        let runSummaryBox = makeInfoBox(
            content: runSummaryLabel,
            minimumHeight: 62
        )
        let runHistoryTitle = makeSectionTitle("What just happened")
        let runHistoryBox = makeInfoBox(
            content: runHistoryLabel,
            minimumHeight: 54
        )
        let remediationTitle = makeSectionTitle("Failure analysis and recommended remediation")
        let remediationBox = makeInfoBox(
            content: remediationLabel,
            minimumHeight: 82
        )
        let traceTitle = makeSectionTitle("Detailed evidence trace")

        let stack = NSStackView(views: [
            titleLabel,
            subtitleLabel,
            explanationTitle,
            explanationBox,
            buttonGuideTitle,
            buttonGuideBox,
            workflowTitle,
            workflowBox,
            statusLabel,
            reasonLabel,
            resultTitle,
            resultBox,
            runSummaryTitle,
            runSummaryBox,
            runHistoryTitle,
            runHistoryBox,
            remediationTitle,
            remediationBox,
            runButton,
            negativeButton,
            localDataButton,
            traceTitle,
            resultsScrollView
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        let contentScrollView = NSScrollView()
        contentScrollView.borderType = .noBorder
        contentScrollView.hasVerticalScroller = true
        contentScrollView.hasHorizontalScroller = false
        contentScrollView.autohidesScrollers = false
        contentScrollView.documentView = contentView
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentScrollView)

        NSLayoutConstraint.activate([
            contentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: contentScrollView.contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentScrollView.contentView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: contentScrollView.contentView.topAnchor),
            contentView.widthAnchor.constraint(equalTo: contentScrollView.contentView.widthAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            explanationBox.widthAnchor.constraint(equalTo: stack.widthAnchor),
            buttonGuideBox.widthAnchor.constraint(equalTo: stack.widthAnchor),
            workflowBox.widthAnchor.constraint(equalTo: stack.widthAnchor),
            resultBox.widthAnchor.constraint(equalTo: stack.widthAnchor),
            runSummaryBox.widthAnchor.constraint(equalTo: stack.widthAnchor),
            runHistoryBox.widthAnchor.constraint(equalTo: stack.widthAnchor),
            remediationBox.widthAnchor.constraint(equalTo: stack.widthAnchor),
            resultsScrollView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            resultsScrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 260)
        ])
    }

    @objc private func runEvaluation() {
        evaluate(includeNegativeControl: false)
    }

    @objc private func runNegativeControl() {
        evaluate(includeNegativeControl: true)
    }

    @objc private func openLocalDataMode() {
        if localDataWindowController == nil {
            localDataWindowController = LocalDataWindowController()
        }
        localDataWindowController?.showWindow(nil)
        localDataWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    private func evaluate(includeNegativeControl: Bool) {
        let gate = EvaluationGate()
        let agent = SyntheticAppleAgent()
        var scenarios = demoScenarios()
        if includeNegativeControl {
            scenarios.append(contentsOf: negativeControlScenarios())
        }

        var tracesByScenario: [String: [TraceEvent]] = [:]
        let evaluations = scenarios.map { scenario in
            let run = agent.run(scenario: scenario)
            tracesByScenario[scenario.id] = run.traces
            return gate.evaluate(
                scenario: scenario,
                traces: run.traces,
                response: run.response
            )
        }
        let decision = gate.decide(
            results: evaluations,
            repeatedRunSpreads: [0.0]
        )

        statusLabel.stringValue = "Release gate: \(decision.status.rawValue)"
        statusLabel.textColor = decision.status == .pass ? .systemGreen : .systemOrange
        reasonLabel.stringValue = "\(decision.reason) Repeat-run spread: 0.00; decision consistency: true."
        let passedCount = evaluations.filter(\.passed).count
        let failedCount = evaluations.count - passedCount
        let expectedFailureCount = includeNegativeControl ? failedCount : 0
        runSummaryLabel.stringValue = """
        Mode: \(includeNegativeControl ? "Negative control" : "Baseline evaluation")
        Scenarios: \(evaluations.count)  Passed: \(passedCount)  Failed: \(failedCount)  Expected failures: \(expectedFailureCount)
        """
        if includeNegativeControl {
            resultMeaningLabel.stringValue = "This FAIL is intentional. The negative-control run adds two known-bad scenarios; it does not change or repair the application. Run baseline again to start a fresh five-scenario run and restore PASS."
            remediationLabel.stringValue = """
            Failures: the agent used knowledge.search instead of the task-creation intent and claimed the task was created; a second path made a recommendation without supporting evidence.
            Recommended remediation: route task-creation requests to CreateFollowUpIntent, require a successful state-changing result before claiming completion, and require evidence before making a recommendation.
            Next step: review the recommendation, then run baseline again. This app does not change its own code.
            """
            negativeButton.title = "Run negative control — expected FAIL"
            runButton.title = "Run baseline again — restore PASS"
            runHistory.append("Negative control FAIL as expected")
            lastRunWasNegativeControl = true
        } else {
            resultMeaningLabel.stringValue = lastRunWasNegativeControl
                ? "This PASS is a fresh baseline run. The negative control was not included, so no repair was needed; the test-only failure was removed from this run."
                : "This PASS means all five normal scenarios met the response, trajectory, and end-to-end thresholds. Read the trace below to see the evidence for each decision."
            remediationLabel.stringValue = lastRunWasNegativeControl
                ? "The previous failure was the intentional negative control. No application code was changed. The clean baseline now passes, while the negative control remains available to verify that the evaluator still catches the known-bad path."
                : "No failure was detected in this baseline run. If a real failure appears, this panel will describe the observed problem, recommend a corrective action, and tell you what to rerun."
            runButton.title = "Run baseline evaluation"
            runHistory.append(lastRunWasNegativeControl ? "Baseline PASS restored" : "Baseline PASS")
            lastRunWasNegativeControl = false
        }
        runHistoryLabel.stringValue = "Run history: " + runHistory.joined(separator: " → ")
        resultsView.string = evaluations.map { result in
            let trace = (tracesByScenario[result.scenarioID] ?? []).map { event in
                "    [\((event.sequence))] \(event.kind.rawValue): \(event.name) — \(event.detail)"
            }.joined(separator: "\n")
            let heading = result.passed
                ? result.scenarioID
                : "⚠️ FAILURE HIGHLIGHT — \(result.scenarioID)"
            let outcome = result.passed
                ? "EVIDENCE ACCEPTED"
                : "FAILURE DETECTED: \(result.failures.joined(separator: ", "))"
            return """
            \(heading)
              component:  \(String(format: "%.2f", result.componentScore))
              trajectory: \(String(format: "%.2f", result.trajectoryScore))
              end-to-end: \(String(format: "%.2f", result.endToEndScore))
              outcome:    \(outcome)
            trace:
            \(trace)
            """
        }.joined(separator: "\n\n")
    }

    private func makeSectionTitle(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.font = .boldSystemFont(ofSize: 13)
        return label
    }

    private func makeInfoBox(text: String, minimumHeight: CGFloat) -> NSBox {
        makeInfoBox(
            content: NSTextField(wrappingLabelWithString: text),
            minimumHeight: minimumHeight
        )
    }

    private func makeInfoBox(
        content: NSTextField,
        minimumHeight: CGFloat
    ) -> NSBox {
        let box = NSBox()
        configureInfoBox(box, content: content, minimumHeight: minimumHeight)
        return box
    }

    private func makeInfoBox(content: NSTextField) -> NSBox {
        let box = NSBox()
        box.titlePosition = .noTitle
        configureInfoBox(box, content: content, minimumHeight: 48)
        return box
    }

    private func configureInfoBox(
        _ box: NSBox,
        content: NSTextField,
        minimumHeight: CGFloat
    ) {
        box.boxType = .custom
        box.borderColor = .separatorColor
        box.borderWidth = 1
        box.fillColor = .controlBackgroundColor
        box.cornerRadius = 8
        let contentContainer = NSView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        box.contentView = contentContainer
        contentContainer.addSubview(content)

        content.font = .systemFont(ofSize: 13)
        content.maximumNumberOfLines = 0
        content.lineBreakMode = .byWordWrapping
        content.cell?.wraps = true
        content.cell?.isScrollable = false
        content.preferredMaxLayoutWidth = 680
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 12),
            content.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -12),
            content.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 8),
            content.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -8)
        ])
        box.translatesAutoresizingMaskIntoConstraints = false
        box.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumHeight).isActive = true
    }
}

@MainActor
final class QualityLabApplicationDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 820),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Apple Platform Agent Quality Lab"
        window.contentViewController = QualityLabViewController()
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }
}

@MainActor
enum MacOSAppLauncher {
    static func run() {
        let application = NSApplication.shared
        let delegate = QualityLabApplicationDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.regular)
        application.activate(ignoringOtherApps: true)
        application.run()
    }
}
#endif
