# Common Bar

[![CI](https://github.com/oddurs/common-bar/actions/workflows/ci.yml/badge.svg)](https://github.com/oddurs/common-bar/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Hide menu bar items behind one chevron. Hold ⌘ to rearrange. **[oddurs.github.io/common-tools/bar](https://oddurs.github.io/common-tools/bar/)**

- **One chevron.** Every item left of it moves off-screen. Click the chevron to bring them back.
- **An always-hidden section.** Items left of a second, dotted line stay hidden even when the rest are showing. ⌥-click the chevron to see them.
- **Arranged where it lives.** You choose what hides by ⌘-dragging icons past the chevron, the same way macOS rearranges the menu bar.
- **A small Settings window.** Open at login, how long revealed items stay, and which gestures reveal them.
- **Several ways to reveal.** Rest the pointer on empty menu bar space, click it, or swipe down on the bar. Swipe up to hide.
- **Tidies up after itself.** Hidden items go away again after a few seconds, but never while you're still working in the menu bar or one of its menus.
- **The chevron is the edge.** Drop an icon just past it and it hides. The invisible divider that does the hiding snaps back beside the chevron whenever the bar hides.

Free and open source under the MIT licence. No network access, no analytics, no permission prompts.

## Install

Requires macOS 14 or later.

1. Download [CommonBar.zip](https://github.com/oddurs/common-bar/releases/latest/download/CommonBar.zip) from the latest release, unzip it, and move **Common Bar** to Applications.
2. Open it. The build is signed but not notarized, so the first time macOS will say it can't verify the developer. Go to **System Settings › Privacy & Security** and click **Open Anyway**. Alternatively, run:

   ```sh
   xattr -dr com.apple.quarantine "/Applications/Common Bar.app"
   ```

3. Right-click the chevron, choose **Settings…**, and turn on **Open at login**.

## Usage

On first launch the hidden items are shown along with a short set of tips. **How to Arrange…** in the right-click menu brings them back.

- **Choose what hides:** hold ⌘ over the menu bar and drag icons past the chevron to hide them, past the dotted line to keep them always hidden, or right of the chevron to keep them visible.
- **Show hidden items:** click the chevron, click empty menu bar space, rest the pointer on empty menu bar space, or swipe down on the menu bar.
- **Show always-hidden items too:** ⌥-click the chevron. ⌥-click again, or click the chevron, to hide everything.
- **Hide them again:** click the chevron or empty space, or swipe up. Items shown by a click or swipe hide after 10 seconds by default, but not while the pointer is in the menu bar, a menu is open, or a mouse button is held. Items shown by hovering hide half a second after the pointer leaves the menu bar.
- **Rearrange at any time:** hold ⌘ over the menu bar. The dotted line and every hidden item appear until you let go, and stay put mid-drag.
- **Menu:** right-click (or Control-click) the chevron for **How to Arrange…**, **Settings…**, and **Quit Common Bar**.

**Settings** opens from that menu (⌘,) or by opening Common Bar again while it runs:

- **Show Hidden Icons When:** hovering over empty menu bar space, scrolling down on the menu bar, or clicking empty menu bar space. Each can be turned off.
- **General:** **Open at login**, and **Hide again after** 5 seconds, 10 seconds (the default), 30 seconds, 1 minute, or never.
- **Common Tools:** Common Stats, Common Keys, and Common Bar, with a button to open or get each one, and the installed version of Common Bar.

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
