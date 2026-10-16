# Common Bar

[![CI](https://github.com/oddurs/common-bar/actions/workflows/ci.yml/badge.svg)](https://github.com/oddurs/common-bar/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Hide menu bar items behind an invisible divider. Hold ⌘ to rearrange. **[oddurs.github.io/common-tools/bar](https://oddurs.github.io/common-tools/bar/)**

- **One chevron, one invisible line.** Every item left of the line moves off-screen. Click the chevron to bring them back.
- **No settings window.** You choose what hides by ⌘-dragging icons across the line, the same way macOS rearranges the menu bar.
- **Several ways to reveal.** Rest the pointer on empty menu bar space, click it, or swipe down on the bar. Swipe up to hide.
- **Tidies up after itself.** Hidden items go away again after a few seconds, but never while you're still working in the menu bar or one of its menus.
- **Keeps the chevron on screen.** If you drag the line right of the chevron, collapsing leaves the chevron where you can reach it.

Free and open source under the MIT licence. No network access, no analytics, no permission prompts.

## Install

Requires macOS 14 or later.

1. Download [CommonBar.zip](https://github.com/oddurs/common-bar/releases/latest/download/CommonBar.zip) from the latest release, unzip it, and move **Common Bar** to Applications.
2. Open it. The build is signed but not notarized, so the first time macOS will say it can't verify the developer. Go to **System Settings › Privacy & Security** and click **Open Anyway**. Alternatively, run:

   ```sh
   xattr -dr com.apple.quarantine "/Applications/Common Bar.app"
   ```

3. Right-click the chevron and choose **Open at Login**.

## Usage

On first launch the hidden items are shown along with a short set of tips. **How to Arrange…** in the right-click menu brings them back.

- **Choose what hides:** hold ⌘ and drag icons to the left of the line to hide them, or to the right of it to keep them visible.
- **Show hidden items:** click the chevron, click empty menu bar space, rest the pointer on empty menu bar space, or swipe down on the menu bar.
- **Hide them again:** click the chevron or empty space, or swipe up. Items shown by a click or swipe hide after 8 seconds, but not while the pointer is in the menu bar, a menu is open, or a mouse button is held. Items shown by hovering hide half a second after the pointer leaves the menu bar.
- **Rearrange at any time:** hold ⌘ over the menu bar. The line and the hidden items appear until you let go, and stay put mid-drag.
- **Menu:** right-click (or Control-click) the chevron for **How to Arrange…**, **Open at Login**, and **Quit**.

Hover, click, and swipe can each be turned off from Terminal:

```sh
defaults write com.oddurs.reasonal showOnHover -bool false
defaults write com.oddurs.reasonal showOnClick -bool false
defaults write com.oddurs.reasonal showOnScroll -bool false
```

More in the [documentation](https://oddurs.github.io/common-tools/bar/docs/).

## Build from source

The Command Line Tools are enough; Xcode is not required.

```sh
scripts/task build                          # universal build → build/Common Bar.app
mv "build/Common Bar.app" /Applications/
```

## Development

```sh
scripts/setup           # once: wire the git hooks
scripts/agent doctor    # check tools and repository state
```

| Command | Does |
| --- | --- |
| `scripts/task check` | lint + test + build, exactly what CI runs |
| `scripts/agent start <type>/<slug>` | new worktree and branch from `origin/main` |
| `scripts/agent commit "<type>: subject"` | Conventional Commit, checked by the hook |
| `scripts/agent pr` | full check, push, open the pull request |
| `scripts/agent sync` | rebase onto `origin/main` |
| `scripts/agent done` | after merge: remove the worktree and branch |
| `scripts/agent list` | worktrees, branches, and pull request state |

See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow.

The app was called Reasonal before 0.1.0. The executable, bundle identifier, and preference keys keep that name so an existing install keeps its item positions and settings.

## Licence

MIT. See [LICENSE](LICENSE).
