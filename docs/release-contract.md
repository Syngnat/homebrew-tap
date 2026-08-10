# Release Contract

## Package Ownership

| Package | Tap path | Installed artifact |
| --- | --- | --- |
| CLI | `Formula/gonavi.rb` | `gonavi` |
| Desktop | `Casks/gonavi-app.rb` | `GoNavi.app` |

The Formula builds `./cmd/gonavi` from an immutable GoNavi source tag. It must
not invoke the desktop lifecycle or provide a self-update command for Homebrew
installations.

Both packages use GoNavi's existing active-root resolution:
`GONAVI_DATA_ROOT`, then `~/.gonavi/storage_root.json`, then `~/.gonavi`.
Neither package introduces a Homebrew-specific data root. Cask uninstall and
zap behavior must not delete `~/.gonavi` because it is shared with the CLI.

## Assets

Desktop release assets keep these exact names:

```text
GoNavi-${VERSION}-MacOS-Amd64.dmg
GoNavi-${VERSION}-MacOS-Arm64.dmg
```

CLI release assets use a separate lowercase namespace:

```text
gonavi-cli_${VERSION}_darwin_amd64.tar.gz
gonavi-cli_${VERSION}_darwin_arm64.tar.gz
gonavi-cli_${VERSION}_linux_amd64.tar.gz
gonavi-cli_${VERSION}_linux_arm64.tar.gz
gonavi-cli_${VERSION}_windows_amd64.zip
gonavi-cli_${VERSION}_windows_arm64.zip
gonavi-cli_${VERSION}_checksums.txt
```

The desktop `latest.json` must contain only desktop update assets. CLI assets
are built in a separate directory or excluded by an explicit GUI allowlist.

## Publication Gates

The Formula may be merged only after:

1. An immutable GoNavi source tag contains `cmd/gonavi` and `internal/cli`.
2. `brew install --build-from-source Syngnat/tap/gonavi` succeeds on supported
   macOS and Linux runners.
3. `brew test Syngnat/tap/gonavi` exercises `gonavi version` and an offline
   headless command.
4. The CLI uses `HeadlessRuntime`, writes audit records with `source=cli`, and
   passes the transaction, export, cross-process locking, and Darwin CGO-stub
   regression suites defined by GoNavi issue #902.

The Cask may be merged only after:

1. The bundle version matches the immutable release version.
2. Nested code and `GoNavi.app` are signed with Developer ID Application,
   hardened runtime, and a secure timestamp.
3. The DMG is signed, notarized, stapled, and validated.
4. `codesign --verify`, `spctl --assess`, and a clean Homebrew install succeed
   without removing or bypassing macOS quarantine.

Run `script/stage-gonavi-release formula VERSION` and
`GONAVI_APPLE_TEAM_ID=TEAMID script/stage-gonavi-release cask VERSION` to
enforce these gates before the package definitions are created. Formula and
Cask publication are independent:
the Formula does not wait for Apple credentials, while the Cask remains absent
from the default branch until its signed and notarized assets pass validation.
