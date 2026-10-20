#!/usr/bin/env bash
# Copy a static BusyBox next to this Dockerfile.
# Historical deploy on xin-server copied the binary by hand.
# This helper does not install packages and does not change Docker settings.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="${1:-/usr/bin/busybox}"

if [[ ! -e "${ROOT}/index.html" ]]; then
  printf '%s\n' "index.html is missing from ${ROOT}." >&2
  exit 1
fi

if [[ ! -f "${SRC}" || ! -x "${SRC}" ]]; then
  printf '%s\n' "Missing an executable BusyBox at ${SRC}." >&2
  printf '%s\n' "Install the distro package busybox-static, then run this script again." >&2
  exit 1
fi

ldd_out="$(ldd "${SRC}" 2>&1 || true)"
if [[ "${ldd_out}" != *"not a dynamic executable"* ]]; then
  printf '%s\n' "${SRC} is not a static binary. A scratch image needs busybox-static." >&2
  exit 1
fi

cp "${SRC}" "${ROOT}/busybox"
chmod 755 "${ROOT}/busybox"
printf '%s\n' "Copied a static BusyBox into the build context. The binary is gitignored."
printf '%s\n' "Build from ${ROOT} with: sudo docker compose up -d --build"
