import Foundation

/// The status items' autosave names. macOS saves each item's position under its name,
/// and `MenuBar.isEmptySpace` excludes the app's own windows by name, so these never change.
public enum ItemName {
    public static let toggle = "toggle"
    public static let divider = "divider"
    public static let alwaysDivider = "alwaysDivider"
    public static let all: Set<String> = [toggle, divider, alwaysDivider]
}

/// Each status item's saved distance from the right edge of the menu bar; larger is
/// further left. macOS records it as items move, so it is known before they are laid out.
public struct ItemPositions: Equatable, Sendable {
    public var toggle: Double
    public var divider: Double
    public var alwaysDivider: Double

    public init(toggle: Double, divider: Double, alwaysDivider: Double) {
        self.toggle = toggle
        self.divider = divider
        self.alwaysDivider = alwaysDivider
    }

    /// Fills in positions macOS hasn't saved yet. Without one, a new item lands at the far
    /// left, which on a crowded notched display is behind the notch. Each starts just left
    /// of the one before, wherever the user has since moved that one.
    public static func seeded(toggle: Double?, divider: Double?, alwaysDivider: Double?) -> ItemPositions {
        let toggle = toggle ?? 0
        let divider = divider ?? toggle + 1
        return ItemPositions(toggle: toggle, divider: divider, alwaysDivider: alwaysDivider ?? divider + 1)
    }
}

/// How wide each divider is and whether its line shows. A stretched divider pushes
/// everything left of it off-screen.
public struct DividerLayout: Equatable, Sendable {
    public static let hiddenLength: CGFloat = 10_000
    public static let visibleLength: CGFloat = 12

    public var dividerLength: CGFloat
    public var alwaysDividerLength: CGFloat
    public var showsDivider: Bool
    public var showsAlwaysDivider: Bool

    public init(reveal: Reveal, isPeeking: Bool, positions: ItemPositions) {
        let revealed = isPeeking || !reveal.isCollapsed
        let revealsAll = isPeeking || (revealed && reveal.showsAlwaysHidden)
        dividerLength =
            revealed ? Self.visibleLength : Self.length(hiding: positions.divider > positions.toggle)
        // Parked while collapsed too, so a reveal never flashes the always-hidden items.
        alwaysDividerLength =
            revealsAll ? Self.visibleLength : Self.length(hiding: positions.alwaysDivider > positions.divider)
        showsDivider = revealed
        showsAlwaysDivider = revealsAll
    }

    /// A divider dragged out of order would push the items meant to stay visible
    /// off-screen with the rest, including the toggle, so it is left unstretched.
    static func length(hiding inOrder: Bool) -> CGFloat {
        inOrder ? hiddenLength : 0
    }
}
