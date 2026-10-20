#!/usr/bin/env bash
# Sanitized control-flow template. See docs/07-auto-network-auth.md.
#
# This is not the live script from xin-server. The live script stays on the
# server at /usr/local/sbin/bjtu-autologin-check.sh and reads credentials from
# /etc/bjtu-auth/. Neither that script nor those credential files are here.
#
# As published, every placeholder still starts with "<", and the script exits
# before it contacts a network or reads a password. Fill it in only on the
# server, only after the campus network policy allows this machine to log in,
# and do not commit the result.
#
# Recorded security limit: the live login used an HTTPS GET. TLS does not stop
# the campus server from writing the URL, including query parameters, into
# its logs. Do not print that URL. Do not echo the credential files.

set -euo pipefail

CRED_DIR="/etc/captive-portal"
USER_FILE="${CRED_DIR}/username"
PASS_FILE="${CRED_DIR}/password"
WIFI_IF="wlo1"
PROBE_URL="<PROBE_URL>"
PORTAL_MARKER="<PORTAL_PAGE_MARKER>"
EXPECTED_SITE_MARKER="<EXPECTED_SITE_MARKER>"
AUTH_URL="<AUTH_ENDPOINT>"

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

refuse_if_template() {
  local value
  for value in "${PROBE_URL}" "${PORTAL_MARKER}" "${EXPECTED_SITE_MARKER}" "${AUTH_URL}"; do
    if [[ "${value}" == "<"* ]]; then
      die "Refusing to run: placeholders are still unset. Edit this only on the server. Do not commit credentials, tokens, or a portal URL."
    fi
  done
}

# HTTP 200 is not enough. A captive portal often answers 200 with a login page.
# Success here means: status 200, portal marker absent, expected site marker present.
probe_body() {
  curl --silent --show-error --max-time 15 --write-out '\n%{http_code}' "${PROBE_URL}" || true
}

internet_ok() {
  local raw code page
  raw="$(probe_body)"
  code="${raw##*$'\n'}"
  page="${raw%$'\n'*}"
  [[ "${code}" == "200" ]] || return 1
  [[ "${page}" != *"${PORTAL_MARKER}"* ]] || return 1
  [[ "${page}" == *"${EXPECTED_SITE_MARKER}"* ]]
}

portal_marker_present() {
  local raw page
  raw="$(probe_body)"
  page="${raw%$'\n'*}"
  [[ "${page}" == *"${PORTAL_MARKER}"* ]]
}

main() {
  refuse_if_template

  if [[ "$(id -u)" -ne 0 ]]; then
    die "Run as root so the credential directory can stay mode 700."
  fi

  if internet_ok; then
    printf '%s\n' "Internet OK; no login required."
    exit 0
  fi

  if ! portal_marker_present; then
    die "Probe failed and no captive-portal marker was found. Not submitting credentials."
  fi

  if [[ ! -f "${USER_FILE}" || ! -f "${PASS_FILE}" ]]; then
    die "Missing credential files in ${CRED_DIR}. Expected mode 600, owner root."
  fi

  # Current address and MAC are runtime facts. Never hard-code them.
  ip -4 -br addr show dev "${WIFI_IF}" >/dev/null
  ip link show dev "${WIFI_IF}" >/dev/null

  # Live flow after this point, recorded but not republished as a working client:
  # read the two root-only files, submit them once to the campus auth endpoint,
  # parse success or failure, stop on an explicit rejection, then probe again.
  # AUTH_URL is checked above so a half-edited template cannot stumble forward.
  die "Login step is intentionally not implemented in the published template."
}

main "$@"
