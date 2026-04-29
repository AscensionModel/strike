import AppKit

final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    private let settings = SettingsStore.shared
    private let teamField = NSTextField()
    private let nameField = NSTextField()
    private let volumeSlider = NSSlider(value: 0.8, minValue: 0, maxValue: 1, target: nil, action: nil)
    private let volumeLabel = NSTextField(labelWithString: "80%")
    private let notificationsCheckbox = NSButton(checkboxWithTitle: "Show a notification when a teammate strikes", target: nil, action: nil)
    private let autoConnectCheckbox = NSButton(checkboxWithTitle: "Connect when Strike opens", target: nil, action: nil)

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 310),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Strike Settings"
        window.center()
        super.init(window: window)
        buildUI()
        loadValues()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        loadValues()
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    private func buildUI() {
        guard let contentView = window?.contentView else {
            return
        }

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22)
        ])

        stack.addArrangedSubview(makeTeamRow())
        stack.addArrangedSubview(makeRow(label: "Your name", field: nameField, placeholder: NSUserName()))
        stack.addArrangedSubview(makeVolumeRow())
        stack.addArrangedSubview(notificationsCheckbox)
        stack.addArrangedSubview(autoConnectCheckbox)

        let buttonRow = NSStackView()
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 10

        let saveButton = NSButton(title: "Save", target: self, action: #selector(save))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancelButton.bezelStyle = .rounded

        buttonRow.addArrangedSubview(NSView())
        buttonRow.addArrangedSubview(cancelButton)
        buttonRow.addArrangedSubview(saveButton)
        buttonRow.setHuggingPriority(.defaultLow, for: .horizontal)
        stack.addArrangedSubview(buttonRow)
        buttonRow.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    }

    private func makeRow(label: String, field: NSTextField, placeholder: String) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12

        let labelView = NSTextField(labelWithString: label)
        labelView.widthAnchor.constraint(equalToConstant: 110).isActive = true

        field.placeholderString = placeholder
        field.lineBreakMode = .byTruncatingMiddle
        field.widthAnchor.constraint(equalToConstant: 310).isActive = true

        row.addArrangedSubview(labelView)
        row.addArrangedSubview(field)
        return row
    }

    private func makeTeamRow() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12

        let labelView = NSTextField(labelWithString: "Team code")
        labelView.widthAnchor.constraint(equalToConstant: 110).isActive = true

        teamField.placeholderString = "ABCD-2345"
        teamField.lineBreakMode = .byTruncatingMiddle
        teamField.widthAnchor.constraint(equalToConstant: 220).isActive = true

        let generateButton = NSButton(title: "Generate", target: self, action: #selector(generateTeamCode))
        generateButton.bezelStyle = .rounded

        row.addArrangedSubview(labelView)
        row.addArrangedSubview(teamField)
        row.addArrangedSubview(generateButton)
        return row
    }

    private func makeVolumeRow() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12

        let labelView = NSTextField(labelWithString: "Volume")
        labelView.widthAnchor.constraint(equalToConstant: 110).isActive = true

        volumeSlider.target = self
        volumeSlider.action = #selector(volumeChanged)
        volumeSlider.numberOfTickMarks = 0
        volumeSlider.widthAnchor.constraint(equalToConstant: 250).isActive = true

        volumeLabel.alignment = .right
        volumeLabel.widthAnchor.constraint(equalToConstant: 48).isActive = true

        row.addArrangedSubview(labelView)
        row.addArrangedSubview(volumeSlider)
        row.addArrangedSubview(volumeLabel)
        return row
    }

    private func loadValues() {
        teamField.stringValue = settings.teamChannel
        nameField.stringValue = settings.displayName
        volumeSlider.doubleValue = Double(settings.volume)
        updateVolumeLabel()
        notificationsCheckbox.state = settings.notificationsEnabled ? .on : .off
        autoConnectCheckbox.state = settings.autoConnect ? .on : .off
    }

    @objc private func save() {
        settings.teamChannel = teamField.stringValue
        settings.displayName = nameField.stringValue
        settings.volume = Float(volumeSlider.doubleValue)
        settings.notificationsEnabled = notificationsCheckbox.state == .on
        settings.autoConnect = autoConnectCheckbox.state == .on
        settings.markFirstLaunchComplete()
        window?.close()
    }

    @objc private func generateTeamCode() {
        settings.regenerateTeamCode()
        teamField.stringValue = settings.teamChannel
    }

    @objc private func volumeChanged() {
        updateVolumeLabel()
    }

    private func updateVolumeLabel() {
        let percent = Int(round(volumeSlider.doubleValue * 100))
        volumeLabel.stringValue = "\(percent)%"
    }

    @objc private func cancel() {
        window?.close()
    }
}
