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
