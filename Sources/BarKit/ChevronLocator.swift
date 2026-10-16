import CoreGraphics

/// Finds the chevron among the menu bar's status item windows. On Tahoe, Control Center
/// draws every status item and AppKit's own window for one doesn't report where it sits,
/// and macOS withholds window names from apps without Screen Recording permission, so
/// the chevron is recognised by shape instead.
public enum ChevronLocator {
    /// The divider sits directly left of the chevron. While collapsed it is stretched
    /// wider than the screen; while revealed it is zero length, so its window is only
    /// macOS's padding: the chevron's own width less `chevronLength`. The rightmost match
    /// wins, because the always-hidden divider, further left, can look like either.
    public static func chevron(among frames: [CGRect], screenWidth: CGFloat, chevronLength: CGFloat) -> CGRect? {
        let sorted = frames.sorted { $0.minX < $1.minX }
        var found: CGRect?
        for (left, right) in zip(sorted, sorted.dropFirst()) where abs(right.minX - left.maxX) < 1 {
            let stretched = left.width >= screenWidth
            let paddingOnly =
                left.width <= maxPadding && abs(right.width - left.width - chevronLength) < 0.5
            if stretched || paddingOnly { found = right }
        }
        return found
    }

    /// Wider than any padding macOS puts around a status item; no real icon is this narrow.
    static let maxPadding: CGFloat = 20
}
