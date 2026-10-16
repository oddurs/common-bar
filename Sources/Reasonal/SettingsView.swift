import BarKit
import SwiftUI

struct SettingsView: View {
    @AppStorage(Preferences.showOnHover) private var showOnHover = true
    @AppStorage(Preferences.showOnScroll) private var showOnScroll = true
    @AppStorage(Preferences.showOnClick) private var showOnClick = true
    @AppStorage(Preferences.autoHide) private var autoHide = AutoHide.standard
    @State private var openAtLogin = LoginItem.isEnabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Section {
                Toggle("Open at Login", isOn: $openAtLogin)
                Picker("Hide Again After", selection: $autoHide) {
                    ForEach(AutoHide.allCases) { delay in
                        Text(Self.title(for: delay)).tag(delay)
                    }
                }
            }

            Section {
                Toggle("Hovering over empty menu bar space", isOn: $showOnHover)
                Toggle("Scrolling down on the menu bar", isOn: $showOnScroll)
                Toggle("Clicking empty menu bar space", isOn: $showOnClick)
            } header: {
                Text("Show Hidden Icons When")
            } footer: {
                Text(
                    "Hold ⌘ over the menu bar to show every icon and drag them between sections. "
                        + "Option-click the chevron to include always-hidden icons."
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("Version", value: Self.version)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: openAtLogin) { _, enabled in
            guard enabled != LoginItem.isEnabled else { return }
            do {
                try LoginItem.setEnabled(enabled)
            } catch {
                loginError = error.localizedDescription
                openAtLogin = LoginItem.isEnabled
            }
        }
        .alert(
            "Couldn’t Change Open at Login",
            isPresented: Binding(get: { loginError != nil }, set: { if !$0 { loginError = nil } })
        ) {
            Button("OK") {}
        } message: {
            Text(loginError ?? "")
        }
    }

    private static func title(for delay: AutoHide) -> String {
        switch delay {
        case .fiveSeconds: "5 Seconds"
        case .tenSeconds: "10 Seconds"
        case .thirtySeconds: "30 Seconds"
        case .oneMinute: "1 Minute"
        case .never: "Never"
        }
    }

    private static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development"
    }
}
