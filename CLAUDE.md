# Working in this repository

<!-- standard:begin about -->
Common Bar is a native macOS menu bar app written in Swift (AppKit plus SwiftUI) with no package dependencies. It hides the menu bar items left of an invisible divider.
<!-- standard:end about -->

## The seam

Do all automation through `scripts/task`. CI and the git hooks call nothing else.

```sh
scripts/task fmt          # format in place
scripts/task fmt:check    # swift format lint --strict
scripts/task lint         # fmt:check, then a debug build with warnings as errors
scripts/task test [name]  # the Swift Testing suites; a name filters them
scripts/task build        # universal "build/Common Bar.app", signed (see scripts/dev-cert)
scripts/task package      # dist/CommonBar.zip and checksums, as a release publishes them
scripts/task run          # build, quit the running copy, open the new one
scripts/task check        # lint + test + build: what CI runs
```

## Workflow

- Never commit to `main`. It only moves forward when a pull request is merged; the `pre-push` hook and branch protection both enforce this.
- One unit of work gets one worktree, one branch, and one pull request: `scripts/agent start <type>/<slug>`, then work in the printed path and finish with `scripts/agent ship "<type>(scope): subject" "<why>" --body-file <pr.md>`, where the body states the problem, the approach, and where a reviewer should be sceptical. It commits, checks, opens the pull request with auto-merge, keeps it rebased while CI runs, and cleans up after the merge. If it stops on a failed check or a conflict, fix the cause and run it again.
- Branch types: `feat fix chore docs perf refactor test`. The branch's first commit names the pull request and the squash commit on `main`.
- Never use `--no-verify`.
- User-facing changes go under `## [Unreleased]` in `CHANGELOG.md` in the same pull request. The site shows each release's section as "What's new".
- Release with `scripts/release <version>`. Never tag by hand.
- This repository follows the Common Tools app standard (`standard/` in oddurs/common-tools). Change shared files there and apply them to every app; only the regions between `standard:begin` and `standard:end` belong to this app.

## Commits

Conventional Commits: `type(scope): subject`. Write the subject in the imperative, at most 72 characters, with no trailing period. The body says why. Never add assistant or tool attribution: no co-author trailers, no "generated with" footers. The `commit-msg` hook rejects them.

## Code

<!-- standard:begin code -->
- The app was called Reasonal. Keep the bundle id `com.oddurs.reasonal`, the `Reasonal` executable target, the status item autosave names, and the UserDefaults keys: existing installs keep their item positions, preferences, and login item only while these stay put. `BundleTests` guards the bundle identifiers.
- Only the visible name is Common Bar: `CFBundleName`, `CFBundleDisplayName`, and menu text.
- `Sources/BarKit` holds every decision that can be made from plain values: divider lengths from saved positions (`DividerLayout`), the seed chain and autosave names (`ItemPositions`, `ItemName`), what a click does (`Reveal`), and the ⌘-peek, hover, and scroll state machines (`Peek`, `Hover`, `ScrollGesture`). It imports no AppKit and takes the time as a parameter, so it is tested without a menu bar.
- `Sources/Reasonal` is the thin app shell. `MenuBarController.swift` owns the status items, reads events and defaults, and feeds BarKit. `MenuBar.swift` answers where things are in the menu bar. Nothing needs a permission prompt; keep it that way, and don't add private APIs.
- Status item positions are read from the `NSStatusItem Preferred Position <name>` defaults macOS writes, because item windows aren't laid out at launch.
- A behaviour change goes into BarKit with a test first; the shell should only translate between AppKit and BarKit.
- A bug fix comes with the test that would have caught it.
- The app icon comes from `swift scripts/make-icon.swift`, which writes `Resources/AppIcon.icns` and `docs/icon.png`. Edit the script, not the images.
<!-- standard:end code -->
