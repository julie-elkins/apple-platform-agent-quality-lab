#if canImport(AppKit)
import AppKit
import UniformTypeIdentifiers

@MainActor
final class LocalDataWindowController: NSWindowController {
    private let sourceLabel = NSTextField(wrappingLabelWithString: "No local file selected.")
    private let resultLabel = NSTextField(
        wrappingLabelWithString: "Local data result: NOT RUN"
    )
    private let previewView = NSTextView()
    private let evidenceView = NSTextView()
    private let traceView = NSTextView()
    private let runButton = NSButton()
    private var localDocument: LocalDataDocument?

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 780),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Local Data Mode — Apple Platform Agent Quality Lab"
        super.init(window: window)
        configureWindow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureWindow() {
        guard let contentView = window?.contentView else {
            return
        }

        let titleLabel = NSTextField(labelWithString: "Local Data Mode")
        titleLabel.font = .boldSystemFont(ofSize: 22)

        let subtitleLabel = NSTextField(
            wrappingLabelWithString: "Evaluate a user-selected file locally while keeping the synthetic release gate separate."
        )
        subtitleLabel.textColor = .secondaryLabelColor

        let safetyBox = makeInfoBox(
            text: """
            Select a de-identified Markdown, text, or JSON file. The app reads it locally,
            does not upload it, and never writes back to the source file. This run is a
            demonstration of real input handling; it does not replace the stable baseline.
            """,
            minimumHeight: 78
        )
        let stepsTitle = makeSectionTitle("Steps in this window")
        let stepsBox = makeInfoBox(
            text: """
            1. Load a de-identified local file.
            2. Run the local evaluation.
            3. Review the preview, evaluation details, and evidence trace.
            4. Return to the Quality Lab to run the baseline and controls.
            """,
            minimumHeight: 104
        )

        sourceLabel.font = .systemFont(ofSize: 13)
        sourceLabel.textColor = .secondaryLabelColor
        resultLabel.font = .boldSystemFont(ofSize: 16)

        configureTextView(previewView)
        configureTextView(evidenceView)
        configureTextView(traceView)
        previewView.string = "No file preview yet."
        evidenceView.string = "Load a de-identified Markdown or JSON file to begin."
        traceView.string = "No local evaluation has run yet."

        let previewScrollView = makeScrollView(documentView: previewView, height: 150)
        let evidenceScrollView = makeScrollView(documentView: evidenceView, height: 150)
        let traceScrollView = makeScrollView(documentView: traceView, height: 220)

        let loadButton = NSButton(
            title: "Load local Markdown or JSON",
            target: self,
            action: #selector(loadLocalFile)
        )
        loadButton.bezelStyle = .rounded

        runButton.title = "Run local data evaluation"
        runButton.bezelStyle = .rounded
        runButton.target = self
        runButton.action = #selector(runLocalEvaluation)
        runButton.isEnabled = false

        let returnButton = NSButton(
            title: "Return to Quality Lab",
            target: self,
            action: #selector(returnToQualityLab)
        )
        returnButton.bezelStyle = .rounded

        let sourceTitle = makeSectionTitle("Selected source")
        let previewTitle = makeSectionTitle("Read-only source preview")
        let resultTitle = makeSectionTitle("Local evaluation result")
        let evidenceTitle = makeSectionTitle("Evaluation details")
        let traceTitle = makeSectionTitle("Local evidence trace")

        let buttonRow = NSStackView(views: [loadButton, runButton, returnButton])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 10
        buttonRow.alignment = .centerY

        let resultBox = makeInfoBox(content: resultLabel, minimumHeight: 42)

        let stack = NSStackView(views: [
            titleLabel,
            subtitleLabel,
            safetyBox,
            stepsTitle,
            stepsBox,
            sourceTitle,
            sourceLabel,
            buttonRow,
            previewTitle,
            previewScrollView,
            resultTitle,
            resultBox,
            evidenceTitle,
            evidenceScrollView,
            traceTitle,
            traceScrollView
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        let documentView = NSView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(stack)

        let contentScrollView = NSScrollView()
        contentScrollView.borderType = .noBorder
        contentScrollView.hasVerticalScroller = true
        contentScrollView.hasHorizontalScroller = false
        contentScrollView.autohidesScrollers = false
        contentScrollView.documentView = documentView
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(contentScrollView)

        NSLayoutConstraint.activate([
            contentScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentScrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            documentView.leadingAnchor.constraint(equalTo: contentScrollView.contentView.leadingAnchor),
            documentView.trailingAnchor.constraint(equalTo: contentScrollView.contentView.trailingAnchor),
            documentView.topAnchor.constraint(equalTo: contentScrollView.contentView.topAnchor),
            documentView.widthAnchor.constraint(equalTo: contentScrollView.contentView.widthAnchor),
            stack.leadingAnchor.constraint(equalTo: documentView.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: documentView.trailingAnchor, constant: -22),
            stack.topAnchor.constraint(equalTo: documentView.topAnchor, constant: 22),
            stack.bottomAnchor.constraint(equalTo: documentView.bottomAnchor, constant: -22),
            safetyBox.widthAnchor.constraint(equalTo: stack.widthAnchor),
            stepsBox.widthAnchor.constraint(equalTo: stack.widthAnchor),
            sourceLabel.widthAnchor.constraint(equalTo: stack.widthAnchor),
            previewScrollView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            resultBox.widthAnchor.constraint(equalTo: stack.widthAnchor),
            evidenceScrollView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            traceScrollView.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    @objc private func returnToQualityLab() {
        window?.orderOut(nil)
        NSApp.windows
            .first { $0.title == "Apple Platform Agent Quality Lab" }?
            .makeKeyAndOrderFront(nil)
    }

    @objc private func loadLocalFile() {
        let panel = NSOpenPanel()
        var allowedTypes: [UTType] = [.plainText, .json]
        if let markdown = UTType(filenameExtension: "md") {
            allowedTypes.append(markdown)
        }
        if let markdown = UTType(filenameExtension: "markdown") {
            allowedTypes.append(markdown)
        }
        panel.allowedContentTypes = allowedTypes
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "Load"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let loadedDocument = try LocalDataImporter.load(url: url)
            localDocument = loadedDocument
            sourceLabel.stringValue = "\(loadedDocument.sourceName) • \(loadedDocument.lineCount) lines • \(loadedDocument.byteCount) bytes"
            previewView.string = loadedDocument.preview
            resultLabel.stringValue = "Local data result: READY"
            resultLabel.textColor = .labelColor
            evidenceView.string = "The file is loaded locally. Nothing has been uploaded or written back. Run the evaluation to produce a grounded response and evidence trace."
            runButton.isEnabled = true
        } catch {
            localDocument = nil
            sourceLabel.stringValue = "Could not load \(url.lastPathComponent): \(error.localizedDescription)"
            previewView.string = "No file preview available."
            resultLabel.stringValue = "Local data result: NOT RUN"
            resultLabel.textColor = .labelColor
            evidenceView.string = "Choose a UTF-8 Markdown, text, or valid JSON file no larger than 1 MB."
            runButton.isEnabled = false
        }
    }

    @objc private func runLocalEvaluation() {
        guard let localDocument else {
            return
        }

        let fallbackRun = LocalDataAgent().run(document: localDocument)
        present(run: fallbackRun, document: localDocument)

#if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            Task { [weak self] in
                do {
                    let liveResponse = try await AppleFoundationModelAgent().summarize(
                        notes: localDocument.content
                    )
                    let liveRun = LocalDataAgent().run(
                        document: localDocument,
                        responseOverride: liveResponse,
                        provider: "Apple Foundation Models"
                    )
                    self?.present(run: liveRun, document: localDocument)
                } catch {
                    self?.evidenceView.string += "\nLive model unavailable; the deterministic local result remains visible."
                }
            }
        }
#endif
    }

    private func present(
        run: (response: String, traces: [TraceEvent]),
        document: LocalDataDocument
    ) {
        let scenario = localDataScenario(sourceName: document.sourceName)
        let gate = EvaluationGate()
        let evaluation = gate.evaluate(
            scenario: scenario,
            traces: run.traces,
            response: run.response
        )
        let decision = gate.decide(results: [evaluation], repeatedRunSpreads: [0.0])

        resultLabel.stringValue = "Local data result: \(decision.status.rawValue)"
        resultLabel.textColor = decision.status == .pass ? .systemGreen : .systemOrange
        evidenceView.string = """
        Source: \(document.sourceName)
        Evidence: \(evaluation.evidenceCount) events • response \(String(format: "%.2f", evaluation.componentScore)) • trajectory \(String(format: "%.2f", evaluation.trajectoryScore)) • end-to-end \(String(format: "%.2f", evaluation.endToEndScore))
        Response: \(run.response)
        """
        traceView.string = run.traces.map { event in
            "[\((event.sequence))] \(event.kind.rawValue): \(event.name) — \(event.detail)"
        }.joined(separator: "\n")
    }

    private func configureTextView(_ textView: NSTextView) {
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        )
    }

    private func makeScrollView(documentView: NSView, height: CGFloat) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.borderType = .bezelBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.documentView = documentView
        scrollView.heightAnchor.constraint(equalToConstant: height).isActive = true
        return scrollView
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

    private func makeInfoBox(content: NSTextField, minimumHeight: CGFloat) -> NSBox {
        let box = NSBox()
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
        return box
    }
}
#endif
