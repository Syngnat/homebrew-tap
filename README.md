# GoNavi Homebrew Tap

Homebrew packages for [GoNavi](https://gonavi.org/).

The tap is being prepared for two packages:

- `gonavi`: the headless CLI, installed as a Formula.
- `gonavi-app`: the macOS desktop application, installed as a Cask.

The packages are not published on the default branch yet. The Formula waits for
the first immutable source tag containing `cmd/gonavi`; the Cask waits for a
Developer ID-signed and notarized DMG. This prevents Homebrew from exposing a
package that cannot build or pass Gatekeeper.

Once those release gates are satisfied, installation will be:

```sh
brew install Syngnat/tap/gonavi
brew install --cask Syngnat/tap/gonavi-app
```

See [docs/release-contract.md](docs/release-contract.md) for the package and
asset contracts.

## Maintainer staging

Package definitions are generated only after their release gates pass:

```sh
script/stage-gonavi-release formula 0.9.3
GONAVI_APPLE_TEAM_ID=ABCDE12345 script/stage-gonavi-release cask 0.9.3
```

The Formula command downloads the immutable source tag, builds `./cmd/gonavi`
with `CGO_ENABLED=0`, verifies its version and an offline command, and then
writes `Formula/gonavi.rb`. The Cask command verifies both DMGs with codesign,
Gatekeeper, and stapler before writing `Casks/gonavi-app.rb`.
`GONAVI_APPLE_TEAM_ID` pins both DMGs and both apps to the expected signing
identity instead of accepting an arbitrary Developer ID certificate.

The generated files must still pass the tap's macOS and Linux `brew test-bot`
checks in a pull request before they are merged into `main`.
