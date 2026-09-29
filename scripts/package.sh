#!/usr/bin/env bash
# Builds one platform's npm-layout plugin tarball from the official ripgrep
# release archive: package/bin/rg is BurntSushi's binary, unmodified, verified
# against the release's published .sha256. package.json declares it as the
# `rg` bin (on every agent's PATH) and the `rg` resource (the app's search).
#
# usage: package.sh <npm-platform> <ripgrep-version> <cache-dir> <build-dir> <out.tgz>
set -euo pipefail

platform="$1" version="$2" cache="$3" work="$4" out="$5"

case "$platform" in
  darwin-arm64) target=aarch64-apple-darwin ext=tar.gz exe= ;;
  darwin-x64) target=x86_64-apple-darwin ext=tar.gz exe= ;;
  # musl: static, runs on any x64 distro regardless of glibc.
  linux-x64) target=x86_64-unknown-linux-musl ext=tar.gz exe= ;;
  linux-arm64) target=aarch64-unknown-linux-gnu ext=tar.gz exe= ;;
  win32-x64) target=x86_64-pc-windows-msvc ext=zip exe=.exe ;;
  *) echo "unsupported platform: $platform" >&2; exit 1 ;;
esac

name="ripgrep-$version-$target"
source="$cache/$name.$ext"
base="https://github.com/BurntSushi/ripgrep/releases/download/$version"
if [ ! -f "$source" ]; then
  echo "downloading $name.$ext"
  curl -fsSL --retry 3 -o "$source.part" "$base/$name.$ext"
  mv "$source.part" "$source"
fi

# Windows sums are CertUtil output, so take the first 64-hex token.
expected="$(curl -fsSL --retry 3 "$base/$name.$ext.sha256" | grep -Eoi '[0-9a-f]{64}' | head -1 | tr 'A-F' 'a-f')"
actual="$(shasum -a 256 "$source" | awk '{print $1}')"
[ "$expected" = "$actual" ] || { echo "$name.$ext sha256 $actual != published $expected" >&2; exit 1; }

unpack="$work/unpack-$platform"
package="$work/$platform/package"
rm -rf "$unpack" "$work/$platform" && mkdir -p "$unpack" "$package/bin"
case "$ext" in
  tar.gz) tar -xzf "$source" -C "$unpack" ;;
  zip) unzip -q "$source" -d "$unpack" ;;
esac
home="$unpack/$name"

cp "$home/rg$exe" "$package/bin/rg$exe"
chmod 755 "$package/bin/rg$exe"
cp "$home/COPYING" "$home/LICENSE-MIT" "$home/UNLICENSE" README.md "$package/"

resources="$(jq -n --arg path "bin/rg$exe" \
  '{rg: {path: $path, description: "ripgrep binary the app runs for file and content search"}}')"
jq --arg platform "$platform" --argjson resources "$resources" \
  '.molt.platforms = [$platform] | .molt.contributes.resources = $resources' \
  package.json > "$package/package.json"

# No AppleDouble `._*` entries in the tarball.
if tar --version 2>/dev/null | grep -q bsdtar; then
  COPYFILE_DISABLE=1 tar --no-mac-metadata -czf "$out" -C "$work/$platform" package
else
  tar -czf "$out" -C "$work/$platform" package
fi
rm -rf "$unpack" "$work/$platform"
echo "built $out ($(du -h "$out" | cut -f1))"
