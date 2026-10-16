# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-10-16

### Added

- A chevron in the menu bar and an invisible divider to its left. Collapsing stretches the divider so every item left of it moves off-screen.
- Click the chevron to show or hide the items.
- Rest the pointer on empty menu bar space, click it, or swipe down on the menu bar to show hidden items. Swipe up to hide them again.
- Items shown by a click or swipe hide again after 8 seconds, but not while the pointer is in the menu bar or a menu is open. Items shown by hovering hide half a second after the pointer leaves the menu bar.
- Hold ⌘ over the menu bar to show the divider and hidden items, then ⌘-drag icons across the divider to choose what hides.
- If the divider is dragged right of the chevron, collapsing leaves the chevron on screen.
- First-launch tips, also available from **How to Arrange…** in the right-click menu, along with **Open at Login** and **Quit**.
- Universal (Apple silicon and Intel) builds for macOS 14 and later.

[Unreleased]: https://github.com/oddurs/common-bar/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/oddurs/common-bar/releases/tag/v0.1.0
