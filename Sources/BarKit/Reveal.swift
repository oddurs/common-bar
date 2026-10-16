/// Whether the hidden items are showing, and whether the always-hidden ones are too.
public struct Reveal: Equatable, Sendable {
    public private(set) var isCollapsed: Bool
    /// Only ever true while expanded.
    public private(set) var showsAlwaysHidden = false

    public init(isCollapsed: Bool) {
        self.isCollapsed = isCollapsed
    }

    /// Returns whether anything changed.
    public mutating func set(collapsed: Bool, showingAlwaysHidden: Bool = false) -> Bool {
        guard collapsed != isCollapsed || showingAlwaysHidden != showsAlwaysHidden else { return false }
        isCollapsed = collapsed
        showsAlwaysHidden = !collapsed && showingAlwaysHidden
        return true
    }

    /// Expands without changing whether the always-hidden items show, as hover and the
    /// tips do.
    public mutating func expand() {
        isCollapsed = false
    }

    /// Where a click on the chevron leads. A plain click toggles the hidden items; an
    /// ⌥-click opens everything, or closes it if everything is already showing. Without
    /// an always-hidden section, an ⌥-click is a plain click.
    public func afterClick(option: Bool, alwaysHidden: Bool) -> (collapsed: Bool, showingAlwaysHidden: Bool) {
        guard option && alwaysHidden else { return (!isCollapsed, false) }
        let allShowing = !isCollapsed && showsAlwaysHidden
        return (allShowing, !allShowing)
    }
}
