# molt-ripgrep

[ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) packaged as a Molt Code
plugin. Molt installs it on first launch; it replaces the old Pythonx
(PyPI `ripgrep`) install.

What it contributes:

- **`rg` resource**: the binary the app runs for file search, content search
  and session search.
- **`rg` bin**: `rg` on every agent's PATH through `~/.moltcode/bin/rg`.

The binaries are the official BurntSushi/ripgrep release builds, unmodified.
`scripts/package.sh` checks each archive against upstream's published
`.sha256` before packaging it. Linux x64 uses the static musl build.

| Platform | Upstream target |
| --- | --- |
| darwin-arm64 | aarch64-apple-darwin |
| darwin-x64 | x86_64-apple-darwin |
| linux-x64 | x86_64-unknown-linux-musl |
| linux-arm64 | aarch64-unknown-linux-gnu |
| win32-x64 | x86_64-pc-windows-msvc |

## Release

```sh
make dist      # out/: one tarball per platform + artifacts.json
make release   # uploads out/ as GitHub release v<version>
```

Pin the Molt catalog (`Moltcode.Agent.Plugins`) from the uploaded assets'
`artifacts.json`. Assets are never replaced; bump the `-<revision>` suffix
instead.

## License

ripgrep is dual-licensed under MIT or the Unlicense (`COPYING`,
`LICENSE-MIT`, `UNLICENSE`), and so is this packaging.
