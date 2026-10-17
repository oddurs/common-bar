import BarKit
import SwiftUI

/// Laid out by the Common Tools Settings standard: the app's own sections, then General, then
/// `CommonToolsSection`, so the three apps' Settings windows read the same.
struct SettingsView: View {
    @AppStorage(Preferences.showOnHover) private var showOnHover = true
    @AppStorage(Preferences.showOnScroll) private var showOnScroll = true
    @AppStorage(Preferences.showOnClick) private var showOnClick = false
    @AppStorage(Preferences.autoHide) private var autoHide = AutoHide.standard
    @AppStorage(Preferences.alwaysHiddenSection) private var alwaysHiddenSection = false
    @AppStorage(Preferences.spacers) private var spacerCount = 0
    @State private var openAtLogin = LoginItem.isEnabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Section {
                Toggle("Hovering over empty menu bar space", isOn: $showOnHover)
                Toggle("Scrolling down on the menu bar", isOn: $showOnScroll)
                Toggle("Clicking empty menu bar space", isOn: $showOnClick)
            } header: {
                Text("Show Hidden Icons When")
            } footer: {
                Text("Hold ⌘ over the menu bar to show every icon, then drag one past the chevron to hide it.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section {
                Stepper(value: $spacerCount, in: 0...Spacers.maxCount) {
                    LabeledContent("Spacers", value: spacerCount == 0 ? "None" : "\(spacerCount)")
                }
            } header: {
                Text("Spacers")
            } footer: {
                Text("Blank gaps between icons. Hold ⌘ over the menu bar to see them, then drag them into place.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Open at login", isOn: $openAtLogin)
                Picker("Hide again after", selection: $autoHide) {
                    ForEach(AutoHide.allCases) { delay in
                        Text(Self.title(for: delay)).tag(delay)
                    }
                }
                Toggle("Always-hidden section", isOn: $alwaysHiddenSection)
            } header: {
                Text("General")
            } footer: {
                Text(loginError ?? "Icons left of the dotted line show only with ⌥-click or while holding ⌘.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            CommonToolsSection()
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: openAtLogin) { _, enabled in
            guard enabled != LoginItem.isEnabled else { return }
            do {
                try LoginItem.setEnabled(enabled)
                loginError = nil
            } catch {
                loginError = error.localizedDescription
                openAtLogin = LoginItem.isEnabled
            }
        }
    }

    private static func title(for delay: AutoHide) -> String {
        switch delay {
        case .fiveSeconds: "5 seconds"
        case .tenSeconds: "10 seconds"
        case .thirtySeconds: "30 seconds"
        case .oneMinute: "1 minute"
        case .never: "Never"
        }
    }
}
