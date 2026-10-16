import SwiftUI

struct TipsView: View {
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tidy Your Menu Bar")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                tip(
                    "command",
                    "Hold ⌘ over the menu bar and drag icons past the chevron to hide them."
                )
                tip(
                    "cursorarrow.motionlines", "Hover, scroll down, or click empty menu bar space to show hidden icons."
                )
                tip("gearshape", "Turn on an always-hidden section in Settings for icons you almost never need.")
            }

            HStack {
                Spacer()
                Button("Done", action: dismiss)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 290)
    }

    private func tip(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
