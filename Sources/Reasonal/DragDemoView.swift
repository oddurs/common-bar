import BarKit
import SwiftUI

/// Draws `DragDemo` over the real menu bar: a stand-in icon carried past the chevron by
/// a cursor, and a caption below with the ⌘ key held. Positions are in the overlay's
/// own coordinates, top-left origin.
struct DragDemoView: View {
    enum Layout {
        static let iconSize: CGFloat = 14
        static let iconCorner: CGFloat = 4
        /// Where the icon starts and is dropped, measured from the chevron's centre.
        static let start: CGFloat = 30
        static let end: CGFloat = -34
        static let captionGap: CGFloat = 8
    }

    let start: Date
    let chevronX: CGFloat
    let barHeight: CGFloat
    let animated: Bool

    var body: some View {
        if animated {
            TimelineView(.animation) { context in
                scene(DragDemo.frame(at: context.date.timeIntervalSince(start)))
            }
        } else {
            // Reduce Motion: the moment the icon lands past the chevron, held still.
            scene(DragDemo.frame(at: 2.0))
        }
    }

    private func scene(_ frame: DragDemo.Frame) -> some View {
        let x = chevronX + Layout.start + (Layout.end - Layout.start) * frame.progress
        let y = barHeight / 2 - frame.lift
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Layout.iconCorner)
                .fill(.primary.opacity(0.85))
                .frame(width: Layout.iconSize, height: Layout.iconSize)
                .scaleEffect(1 + 0.12 * frame.lift)
                .shadow(color: .black.opacity(0.3 * frame.lift), radius: 3 * frame.lift, y: 1)
                .opacity(frame.iconOpacity)
                .position(x: x, y: y)

            if frame.showsCursor {
                Image(nsImage: NSCursor.arrow.image)
                    .position(x: x + 6, y: y + 8)
            }

            Caption(commandDown: frame.commandDown)
                .fixedSize()
                .frame(width: chevronX + 16, alignment: .trailing)
                .padding(.top, barHeight + Layout.captionGap)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct Caption: View {
    let commandDown: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text("⌘")
                .font(.system(size: 13, weight: .medium))
                .frame(width: 26, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 6).fill(.primary.opacity(commandDown ? 0.22 : 0.06))
                )
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.primary.opacity(0.25), lineWidth: 0.5))
                .scaleEffect(commandDown ? 0.92 : 1)
                .animation(.easeOut(duration: 0.1), value: commandDown)
            Text("Hold ⌘ and drag an icon past the chevron to hide it.")
                .font(.callout)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .modifier(Glass())
    }
}

private struct Glass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(in: RoundedRectangle(cornerRadius: 12))
        } else {
            content.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
