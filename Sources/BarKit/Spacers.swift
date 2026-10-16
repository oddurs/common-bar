import Foundation

/// Blank items the user drags between icons to group them.
public enum Spacers {
    public static let maxCount = 5

    /// Unset or out-of-range values are clamped, so a hand-edited preference can't add dozens.
    public static func count(stored: Any?) -> Int {
        min(max(stored as? Int ?? 0, 0), maxCount)
    }

    /// Just right of the chevron, so a new spacer starts in sight, ready to be dragged.
    /// Positions count from the right edge, so smaller is further right.
    public static func seedPosition(toggle: Double) -> Double {
        max(toggle - 1, 0)
    }
}
