# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.3.0] - 2026-10-16

### Added

- A **Common Tools** section at the end of Settings that lists Common Stats, Common Keys, and Common Bar, opens the ones you have, and links to the others. It also shows Common Bar's version.

### Changed

- Settings follows the layout shared by the Common Tools apps: **Show Hidden Icons When** first, then **General** with **Open at login** and **Hide again after**, then **Common Tools**. Labels are in sentence case, as in System Settings.
- A failure to change **Open at login** shows under the General section instead of in an alert.

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
