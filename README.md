# Common Bar

[![CI](https://github.com/oddurs/common-bar/actions/workflows/ci.yml/badge.svg)](https://github.com/oddurs/common-bar/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Hide menu bar items behind one chevron. Hold ⌘ to rearrange. **[oddurs.github.io/common-tools/bar](https://oddurs.github.io/common-tools/bar/)**

- **One chevron.** Every item left of it moves off-screen. Click the chevron to bring them back.
- **An optional always-hidden section.** Turn it on in Settings, and items left of a dotted line stay hidden even when the rest are showing. ⌥-click the chevron to see them.
- **Arranged where it lives.** You choose what hides by ⌘-dragging icons past the chevron, the same way macOS rearranges the menu bar.
- **Spacers.** Add up to five blank gaps in Settings and drag them between icons to group them.
- **A small Settings window.** Open at login, how long revealed items stay, which gestures reveal them, the always-hidden section, and spacers.
- **Several ways to reveal.** Rest the pointer on empty menu bar space or swipe down on the bar; swipe up to hide. Clicking empty space can reveal too, if you turn it on in Settings.
- **Tidies up after itself.** Hidden items go away again after a few seconds, but never while you're still working in the menu bar or one of its menus.
- **No gaps, nothing reshuffled.** While hidden icons show, the divider that hides them takes up no room. Common Bar never removes or recreates its items, so your arrangement stays exactly where you put it.

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

On first launch a short how-to plays in the menu bar beside the chevron: a ⌘ key is held, and an icon is dragged past the chevron and hides. It plays three times and stops early if you click or hold ⌘. **How to Arrange…** in the right-click menu plays it again.

- **Choose what hides:** hold ⌘ over the menu bar. A hairline appears just left of the chevron; drag icons past it to hide them, or right of the chevron to keep them visible. With the always-hidden section on, drag them past the dotted line to keep them always hidden.
- **Show hidden items:** click the chevron, rest the pointer on empty menu bar space, or swipe down on the menu bar. Clicking empty menu bar space works too once it's turned on in Settings.
- **Show always-hidden items too:** turn on **Always-hidden section** in Settings, then ⌥-click the chevron. ⌥-click again, or click the chevron, to hide everything. With the section off, ⌥-click acts like a click.
- **Hide them again:** click the chevron or empty space, or swipe up. Items shown by a click or swipe hide after 10 seconds by default, but not while the pointer is in the menu bar, a menu is open, or a mouse button is held. Items shown by hovering hide half a second after the pointer leaves the menu bar.
- **Rearrange at any time:** hold ⌘ over the menu bar. Every hidden item, the hairline, and the dotted line if the section is on, appear until you let go, and stay put mid-drag.
- **Group icons with spacers:** set **Spacers** in Settings. New spacers appear in the visible part of the bar. They're blank, so hold ⌘ over the menu bar to see their dashed outlines, then drag them into place. Drag one past the chevron and it hides like any icon.
- **Menu:** right-click (or Control-click) the chevron for **How to Arrange…**, **Settings…**, and **Quit Common Bar**.

**Settings** opens from that menu (⌘,) or by opening Common Bar again while it runs:

- **Show Hidden Icons When:** hovering over empty menu bar space, scrolling down on the menu bar, or clicking empty menu bar space. Hovering and scrolling are on to start with, clicking is off; each can be changed.
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
scripts/dev-cert        # optional, once: a stable signing identity, so permissions survive rebuilds
scripts/agent doctor    # check tools and repository state
```

| Command | Does |
| --- | --- |
| `scripts/task run` | build, quit the running copy, open the new one |
| `scripts/task check` | lint + test + build, exactly what CI runs |
| `scripts/task test <name>` | only the tests whose name matches |
| `scripts/agent start <type>/<slug>` | new worktree and branch from `origin/main` |
| `scripts/agent ship "<type>: subject"` | commit, check, open the PR with auto-merge, wait for the merge, clean up |
| `scripts/agent pr` | check, push, open the PR with auto-merge, without waiting |
| `scripts/agent sync` | rebase onto `origin/main` |
| `scripts/agent done` | after a merge: remove the worktree and branch, update the main checkout |
| `scripts/agent list` | worktrees, branches, and pull request state |
| `scripts/release <version>` | a release: dated notes, version bump, tag, published download, checked |

See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow.

The app was called Reasonal before 0.1.0. The executable, bundle identifier, and preference keys keep that name so an existing install keeps its item positions and settings.

## Licence

MIT. See [LICENSE](LICENSE).
