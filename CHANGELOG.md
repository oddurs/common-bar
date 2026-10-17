# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed

- No more blank gaps when hidden icons are showing. The hidden icons used to sit 16 pt away from the chevron, and with the always-hidden section off there was another 16 pt gap among them. A divider with nothing to do now takes up no room, without being removed from the menu bar, so opening and closing stay smooth however often you do it.

### Added

- Spacers: blank gaps you drag between menu bar icons to group them. Choose up to five under **Spacers** in Settings. They're invisible except while you hold ⌘, when a dashed outline shows where each one is.

### Changed

- Clicking empty menu bar space no longer reveals hidden icons unless you turn it on in Settings. A stray click on blank bar space used to open or close the bar.
- Smoother opening and closing. Hidden icons glide in from just past the screen's edge instead of from thousands of points away, the chevron turns with a gentle spring to point the way they go, and the ⌘ hairline fades in.
- While you hold ⌘, a hairline marks where hidden icons begin, just left of the chevron. Icons dropped between it and the chevron stay visible; the divider is no longer moved back beside the chevron behind your back.
- The first-launch tips are now an animated how-to played in the menu bar beside the chevron: holding ⌘ and dragging an icon past the chevron to hide it. It plays three times, stops on any click or when you hold ⌘, and **How to Arrange…** plays it again.

## [0.3.0] - 2026-10-16

### Added

- A **Common Tools** section at the end of Settings that lists Common Stats, Common Keys, and Common Bar, opens the ones you have, and links to the others. It also shows Common Bar's version.

### Changed

- Settings follows the layout shared by the Common Tools apps: **Show Hidden Icons When** first, then **General** with **Open at login** and **Hide again after**, then **Common Tools**. Labels are in sentence case, as in System Settings.
- A failure to change **Open at login** shows under the General section instead of in an alert.
- Quieter menu bar icons: a smaller chevron and a finer dotted line.
- The always-hidden section is optional and off by default. Turn it on with **Always-hidden section** in Settings → General. While it's off there's no dotted line, ⌥-click acts like a click, and icons that were behind the dotted line hide and show with the rest. Turning it back on restores where the line was.

### Fixed

- Icons dragged just past the chevron now hide. Before, they had to go left of a separate line that could drift away from the chevron, and icons dropped between the two stayed visible. The chevron is now the edge, and the solid line is gone; the dotted always-hidden line is unchanged.

## [0.2.1] - 2026-10-16

### Changed

- New app icon, in the blue glass style shared by Common Stats, Common Keys, and Common Bar.

## [0.2.0] - 2026-10-16

### Added

- A Settings window. Open it with **Settings…** (⌘,) in the chevron's right-click menu, or by opening Common Bar again while it runs.
- **Hide Again After:** choose 5 seconds, 10 seconds, 30 seconds, 1 minute, or Never.
- **Show Hidden Icons When:** turn hovering, scrolling down, and clicking empty menu bar space on or off one by one.

### Changed

- **Open at Login** moved from the right-click menu to Settings.
- Revealed items hide again after 10 seconds by default, up from 8.

## [0.1.0] - 2026-10-16

### Added

- A chevron in the menu bar and an invisible divider to its left. Collapsing stretches the divider so every item left of it moves off-screen.
- Click the chevron to show or hide the items.
- Rest the pointer on empty menu bar space, click it, or swipe down on the menu bar to show hidden items. Swipe up to hide them again.
- Items shown by a click or swipe hide again after 8 seconds, but not while the pointer is in the menu bar or a menu is open. Items shown by hovering hide half a second after the pointer leaves the menu bar.
- An always-hidden section behind a second, dotted divider. Its items stay hidden when the others show; ⌥-click the chevron to show everything.
- Hold ⌘ over the menu bar to show both dividers and every hidden item, then ⌘-drag icons across the dividers to choose what hides.
- If a divider is dragged out of order, it doesn't stretch, so collapsing never pushes the chevron or the visible items off-screen.
- First-launch tips, also available from **How to Arrange…** in the right-click menu, along with **Open at Login** and **Quit**.
- Universal (Apple silicon and Intel) builds for macOS 14 and later.

[Unreleased]: https://github.com/oddurs/common-bar/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/oddurs/common-bar/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/oddurs/common-bar/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/oddurs/common-bar/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/oddurs/common-bar/releases/tag/v0.1.0
