import SwiftUI

struct TipsView: View {
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tidy Your Menu Bar")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                tip("command", "Hold ⌘ and drag icons to the left of the line to hide them.")
                tip("chevron.compact.left", "Click the chevron to show hidden icons.")
                tip("cursorarrow.motionlines", "Hold ⌘ over the menu bar anytime to rearrange.")
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
