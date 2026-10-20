#!/usr/bin/env bash
# Copy a static BusyBox into this build context.
# This helper did not run on xin-server during Phase 2. The server steps were
# the package install and a manual copy, recorded in docs/12-offline-container-build.md.
# The script does not install packages and does not change Docker settings.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="${1:-/usr/bin/busybox}"

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
printf '%s\n' "Build with: sudo docker build --pull=false -t xin-offline-hello:1 ${ROOT}"
