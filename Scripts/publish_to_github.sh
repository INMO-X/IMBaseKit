#!/usr/bin/env bash
#
# publish_to_github.sh — sync the binary release into this public checkout.
#
# Env (optional):
#   GITHUB_REPO       default: INMO-X/IMBaseKit
#   PUBLIC_CHECKOUT   local clone of https://github.com/INMO-X/IMBaseKit.git
#                     default: this repository
#
# Public repo is binary-only. Example demo sources live under Example/.
# Library implementation .swift must not be committed.
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GITHUB_REPO="${GITHUB_REPO:-INMO-X/IMBaseKit}"
PUBLIC_CHECKOUT="${PUBLIC_CHECKOUT:-$ROOT}"

if [[ ! -d "$PUBLIC_CHECKOUT/.git" ]]; then
  echo "PUBLIC_CHECKOUT is not a git repository: $PUBLIC_CHECKOUT" >&2
  exit 1
fi

VERSION="$(ruby -e "require 'cocoapods'; puts Pod::Specification.from_file('$ROOT/IMBaseKit.podspec').version")"

rsync -a --delete "$ROOT/XCFrameworks/" "$PUBLIC_CHECKOUT/XCFrameworks/"

leaked="$(find "$PUBLIC_CHECKOUT" -name '*.swift' ! -path '*/Example/*' 2>/dev/null || true)"
if [[ -n "$leaked" ]]; then
  echo "Refusing to publish: .swift sources detected in public checkout:" >&2
  echo "$leaked" >&2
  exit 1
fi

cd "$PUBLIC_CHECKOUT"
git add -A
git commit -m "Release $VERSION"
if git rev-parse "$VERSION" >/dev/null 2>&1; then
  git tag -d "$VERSION" >/dev/null 2>&1 || true
fi
git tag -a "$VERSION" -m "IMBaseKit $VERSION"
echo "Review, then: git push origin HEAD && git push origin $VERSION  # $GITHUB_REPO"
